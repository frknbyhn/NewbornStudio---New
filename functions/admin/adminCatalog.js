const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { requireAdmin } = require("./_util");

// ai_models/categories both have `allow write: if false` for every client (see firestore.rules) —
// these are the only way to create/edit/delete them outside the one-off seedThemes script.

exports.adminUpsertStyle = onCall({}, async (request) => {
  await requireAdmin(request);
  const { styleId, categoryId, categoryName, mood, name, descriptor, prompt, creditCost, aspectRatio, position } = request.data || {};
  if (!styleId || !name) throw new HttpsError("invalid-argument", "styleId and name are required.");

  const fields = { name };
  if (categoryId !== undefined) fields.categoryId = categoryId;
  if (categoryName !== undefined) fields.categoryName = categoryName;
  if (mood !== undefined) fields.mood = mood;
  if (descriptor !== undefined) fields.descriptor = descriptor;
  if (prompt !== undefined) fields.prompt = prompt;
  if (creditCost !== undefined) fields.creditCost = Number(creditCost);
  if (aspectRatio !== undefined) fields.aspectRatio = aspectRatio;
  if (position !== undefined) fields.position = Number(position);

  await getFirestore().collection("ai_models").doc(styleId).set(fields, { merge: true });
  return { success: true, styleId };
});

exports.adminDeleteStyle = onCall({}, async (request) => {
  await requireAdmin(request);
  const { styleId } = request.data || {};
  if (!styleId) throw new HttpsError("invalid-argument", "styleId is required.");
  await getFirestore().collection("ai_models").doc(styleId).delete();
  return { success: true };
});

exports.adminUpsertCategory = onCall({}, async (request) => {
  await requireAdmin(request);
  const { categoryId, name, mood, position } = request.data || {};
  if (!categoryId || !name) throw new HttpsError("invalid-argument", "categoryId and name are required.");

  const fields = { name };
  if (mood !== undefined) fields.mood = mood;
  if (position !== undefined) fields.position = Number(position);

  await getFirestore().collection("categories").doc(categoryId).set(fields, { merge: true });
  return { success: true, categoryId };
});

exports.adminDeleteCategory = onCall({}, async (request) => {
  await requireAdmin(request);
  const { categoryId } = request.data || {};
  if (!categoryId) throw new HttpsError("invalid-argument", "categoryId is required.");
  await getFirestore().collection("categories").doc(categoryId).delete();
  return { success: true };
});
