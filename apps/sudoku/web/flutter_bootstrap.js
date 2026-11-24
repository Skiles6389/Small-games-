{{flutter_js}}
{{flutter_build_config}}

// Starts the Flutter app, then fades out the loading splash in index.html.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (splash) {
      // Give Flutter a moment to paint its first frame underneath.
      setTimeout(() => {
        splash.classList.add('hidden');
        setTimeout(() => splash.remove(), 400);
      }, 150);
    }
  },
});
