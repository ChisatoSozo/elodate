function getCurrentLocation(successCallback, errorCallback) {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        successCallback(position.coords.latitude, position.coords.longitude);
      },
      (error) => {
        errorCallback(error.message);
      }
    );
  } else {
    errorCallback('Geolocation is not supported by this browser.');
  }
}
