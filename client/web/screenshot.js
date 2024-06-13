function capture(x, y, width, height, callback) {
  html2canvas(document.body, {
    x: x,
    y: y,
    width: width - x,
    height: height - y,
  }).then(function (canvas) {
    let base64Image = canvas.toDataURL("image/png");
    let base64ImageWithoutPrefix = base64Image.split(',')[1];
    callback(base64ImageWithoutPrefix);
  }).catch(function (error) {
    console.error('Error capturing image:', error);
  });
};
