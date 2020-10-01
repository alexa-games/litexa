function makeInitialData(appState) {
  return {
    appState: appState,
    greeting: "Hello, player."
  };
}

function makeInitialTransformers() { 
  return [
    {
      transformer: 'textToSpeech',
      inputPath: 'greeting',
    }
  ];
}