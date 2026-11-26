{{flutter_js}}
{{flutter_build_config}}
const version = new URL(document.currentScript.src).searchParams.get('v') || 'clinic-1';
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) build.mainJsPath += '?v=' + encodeURIComponent(version);
}
_flutter.loader.load();
