const fs = require("fs");
const crypto = require("crypto");
const path = require("path");

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const FIRESTORE_SCOPE = "https://www.googleapis.com/auth/datastore";
const FIRESTORE_API_BASE = "https://firestore.googleapis.com/v1";

function getServiceAccountPath() {
  const preferredPath = path.join(__dirname, "serviceAccountKey.json");

  if (fs.existsSync(preferredPath)) {
    return preferredPath;
  }

  const serviceAccountFiles = fs
    .readdirSync(__dirname)
    .filter((fileName) => fileName.endsWith(".json"))
    .filter((fileName) => fileName !== "package.json")
    .filter((fileName) => fileName.includes("firebase-adminsdk"));

  if (serviceAccountFiles.length === 1) {
    return path.join(__dirname, serviceAccountFiles[0]);
  }

  console.error(
    "Missing Firebase service account JSON file. Put it in this folder, then run again."
  );
  process.exit(1);
}

const serviceAccount = require(getServiceAccountPath());
const projectId = serviceAccount.project_id;
const rootDocumentPath = `projects/${projectId}/databases/(default)/documents`;

function base64Url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function createServiceAccountJwt() {
  const nowInSeconds = Math.floor(Date.now() / 1000);
  const header = {
    alg: "RS256",
    typ: "JWT",
  };
  const payload = {
    iss: serviceAccount.client_email,
    scope: FIRESTORE_SCOPE,
    aud: TOKEN_URL,
    iat: nowInSeconds,
    exp: nowInSeconds + 3600,
  };
  const unsignedToken = `${base64Url(JSON.stringify(header))}.${base64Url(
    JSON.stringify(payload)
  )}`;
  const signature = crypto
    .createSign("RSA-SHA256")
    .update(unsignedToken)
    .sign(serviceAccount.private_key, "base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  return `${unsignedToken}.${signature}`;
}

async function getAccessToken() {
  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: createServiceAccountJwt(),
    }),
  });

  if (!response.ok) {
    throw new Error(`Could not get access token: ${await response.text()}`);
  }

  const tokenBody = await response.json();
  return tokenBody.access_token;
}

async function firestoreRequest(accessToken, url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });

  if (!response.ok) {
    throw new Error(`Firestore request failed: ${await response.text()}`);
  }

  return response.json();
}

async function listCollectionIds(accessToken, parentPath) {
  const collectionIds = [];
  let pageToken;

  do {
    const response = await firestoreRequest(
      accessToken,
      `${FIRESTORE_API_BASE}/${parentPath}:listCollectionIds`,
      {
        method: "POST",
        body: JSON.stringify({
          pageSize: 300,
          pageToken,
        }),
      }
    );

    collectionIds.push(...(response.collectionIds || []));
    pageToken = response.nextPageToken;
  } while (pageToken);

  return collectionIds;
}

function documentIdFromName(documentName) {
  return documentName.split("/").pop();
}

async function listDocuments(accessToken, parentPath, collectionId) {
  const documents = [];
  let pageToken;

  do {
    const url = new URL(
      `${FIRESTORE_API_BASE}/${parentPath}/${collectionId}`
    );
    url.searchParams.set("pageSize", "300");

    if (pageToken) {
      url.searchParams.set("pageToken", pageToken);
    }

    const response = await firestoreRequest(accessToken, url.toString());
    documents.push(...(response.documents || []));
    pageToken = response.nextPageToken;
  } while (pageToken);

  return documents;
}

function decodeFirestoreValue(value) {
  if ("nullValue" in value) {
    return null;
  }

  if ("booleanValue" in value) {
    return value.booleanValue;
  }

  if ("integerValue" in value) {
    return Number(value.integerValue);
  }

  if ("doubleValue" in value) {
    return value.doubleValue;
  }

  if ("timestampValue" in value) {
    return value.timestampValue;
  }

  if ("stringValue" in value) {
    return value.stringValue;
  }

  if ("bytesValue" in value) {
    return value.bytesValue;
  }

  if ("referenceValue" in value) {
    return value.referenceValue;
  }

  if ("geoPointValue" in value) {
    return value.geoPointValue;
  }

  if ("arrayValue" in value) {
    return (value.arrayValue.values || []).map(decodeFirestoreValue);
  }

  if ("mapValue" in value) {
    return decodeFirestoreFields(value.mapValue.fields || {});
  }

  return value;
}

function decodeFirestoreFields(fields = {}) {
  const decoded = {};

  for (const [key, value] of Object.entries(fields)) {
    decoded[key] = decodeFirestoreValue(value);
  }

  return decoded;
}

async function backupCollection(accessToken, parentPath, collectionId) {
  const firestoreDocuments = await listDocuments(
    accessToken,
    parentPath,
    collectionId
  );
  const documents = [];

  for (const firestoreDocument of firestoreDocuments) {
    const subcollectionIds = await listCollectionIds(
      accessToken,
      firestoreDocument.name
    );
    const subcollectionBackups = {};

    for (const subcollectionId of subcollectionIds) {
      subcollectionBackups[subcollectionId] = await backupCollection(
        accessToken,
        firestoreDocument.name,
        subcollectionId
      );
    }

    documents.push({
      id: documentIdFromName(firestoreDocument.name),
      name: firestoreDocument.name,
      createTime: firestoreDocument.createTime,
      updateTime: firestoreDocument.updateTime,
      fields: firestoreDocument.fields || {},
      data: decodeFirestoreFields(firestoreDocument.fields || {}),
      subcollections: subcollectionBackups,
    });
  }

  return documents;
}

async function runBackup() {
  const backupsDir = path.join(__dirname, "backups");
  fs.mkdirSync(backupsDir, { recursive: true });

  const accessToken = await getAccessToken();
  const collectionIds = await listCollectionIds(accessToken, rootDocumentPath);
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const outputPath = path.join(backupsDir, `firestore-backup-${timestamp}.json`);
  const backup = {
    createdAt: new Date().toISOString(),
    projectId,
    collections: {},
  };

  for (const collectionId of collectionIds) {
    console.log(`Backing up collection: ${collectionId}`);
    backup.collections[collectionId] = await backupCollection(
      accessToken,
      rootDocumentPath,
      collectionId
    );
  }

  fs.writeFileSync(outputPath, JSON.stringify(backup, null, 2), "utf8");
  console.log(`Backup saved to: ${outputPath}`);
}

runBackup().catch((error) => {
  console.error("Backup failed:", error);
  process.exit(1);
});
