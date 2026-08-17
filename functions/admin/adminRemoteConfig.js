const { onCall } = require("firebase-functions/v2/https");
const { getRemoteConfig } = require("firebase-admin/remote-config");
const { requireAdmin } = require("./_util");

// The three flags this app actually reads — see RemoteConfigService.swift / the
// newborn_moments_remote_config_flags memory. Not a general-purpose Remote Config editor:
// scoped to exactly these keys so the admin panel can't accidentally touch something unrelated.
const KEYS = {
  limitedTimeAction: "BOOLEAN",
  frun: "BOOLEAN",
  introPackage: "STRING",
};

exports.adminGetRemoteConfig = onCall({}, async (request) => {
  await requireAdmin(request);
  const template = await getRemoteConfig().getTemplate();
  const result = {};
  for (const key of Object.keys(KEYS)) {
    const param = template.parameters[key];
    result[key] = param && param.defaultValue && "value" in param.defaultValue ? param.defaultValue.value : null;
  }
  return result;
});

exports.adminSetRemoteConfig = onCall({}, async (request) => {
  await requireAdmin(request);
  const values = request.data || {};
  const rc = getRemoteConfig();
  const template = await rc.getTemplate();

  for (const [key, valueType] of Object.entries(KEYS)) {
    if (!(key in values)) continue;
    const raw = values[key];
    const value = valueType === "BOOLEAN" ? String(!!raw) : String(raw);
    template.parameters[key] = {
      ...(template.parameters[key] || {}),
      valueType,
      defaultValue: { value },
    };
  }

  await rc.validateTemplate(template);
  const published = await rc.publishTemplate(template);
  return { success: true, version: published.version ? published.version.versionNumber : null };
});
