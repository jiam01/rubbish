<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>在线画板</title>
<style>
body {
font-family: Arial, sans-serif;
text-align: center;
background-color: #f0f0f0;
margin: 0;
overflow: hidden;
}

h1 {
color: #333;
}

#canvas-container {
position: absolute;
top: 0;
left: 0;
width: 100vw;
height: 100vh;
display: flex;
align-items: center;
justify-content: center;
overflow: hidden;
}

canvas {
border: 1px solid #333;
background-color: #fff;
opacity: 0.8;
touch-action: none;
}

#color-buttons {
position: absolute;
top: 20px;
left: 20px;
display: flex;
flex-direction: column;
align-items: center;
justify-content: center;
}

#color-buttons button {
margin-bottom: 10px;
}

#size-slider {
position: absolute;
bottom: 20px;
left: 50%;
transform: translateX(-50%);
width: 80%;
transform-origin: center bottom;
}

#size-label {
font-size: 16px;
}

#controls {
position: absolute;
top: 50%;
right: 20px;
transform: translateY(-50%);
display: flex;
flex-direction: column;
align-items: center;
justify-content: center;
transform-origin: top right;
}

#controls button {
margin-bottom: 10px;
}
</style>
</head>
<body>
<h1>在线画板</h1>
<div id="canvas-container">
<canvas id="canvas" width="3200" height="2400"></canvas>
</div>
<div id="color-buttons">
<button onclick="changeColor('black')" style="background-color: black; color: white;">黑色</button>
<button onclick="changeColor('red')" style="background-color: red; color: white;">红色</button>
<button onclick="changeColor('blue')" style="background-color: blue; color: white;">蓝色</button>
<button onclick="changeColor('green')" style="background-color: green; color: white;">绿色</button>
<input type="color" id="custom-color" onchange="changeColor(this.value)">
</div>
<div id="size-slider">
<label for="size" id="size-label">笔画粗细:</label>
<input type="range" id="size" min="1" max="20" value="2" oninput="changeSize(this.value)">
</div>
<div id="controls">
<button onclick="clearCanvas()">清空画布</button>
<button onclick="undo()">撤销</button>
<button onclick="redo()">重画</button>
<button onclick="zoomIn()">放大</button>
<button onclick="zoomOut()">缩小</button>
<button onclick="resetCanvasPosition()">重置画布位置</button>

</div>

<script>
// 获取画布元素和容器
var canvas = document.getElementById("canvas");
var canvasContainer = document.getElementById("canvas-container");
var ctx = canvas.getContext("2d");
var initialTranslateX = 0;
var initialTranslateY = 0;

// 设置初始画笔颜色和粗细
var color = "black";
var size = 2;
var drawing = false;
var steps = [];
var deletedSteps = [];
var lastX = 0;
var lastY = 0;
// 双指触摸相关变量
var initialDistance = 0;
var initialScale = 1;
var initialTranslateX = 0;
var initialTranslateY = 0;
var isTwoFingerTouch = false;

// 设置初始缩放比例
var scale = 1;
var translateX = 0;
var translateY = 0;

canvas.addEventListener("touchstart", handleTouchStart);
canvas.addEventListener("touchmove", handleTouchMove);
canvas.addEventListener("touchend", handleTouchEnd);

// 鼠标事件处理
canvas.addEventListener("mousedown", startDrawing);
canvas.addEventListener("mousemove", draw);
canvas.addEventListener("mouseup", stopDrawing);
canvas.addEventListener("mouseout", stopDrawing);

// 触摸事件处理
canvas.addEventListener("touchstart", startDrawing);
canvas.addEventListener("touchmove", draw);
canvas.addEventListener("touchend", stopDrawing);

// 双指触摸开始
var initialDistance = 0;
var initialScale = 1;

function handleTouchStart(event) {
if (event.touches.length === 2) {
event.preventDefault();
var touch1 = event.touches[0];
var touch2 = event.touches[1];
initialDistance = getDistance(touch1, touch2);
initialScale = scale;
initialTranslateX = translateX; // 修改这里
initialTranslateY = translateY; // 修改这里
isTwoFingerTouch = true;
// 在双指触摸时停止记录笔画
drawing = false;
isTwoFingerTouch = true;
} else {
// 单指操作开始时记录笔画，并清除双指触摸标记
var touch = event.touches[0];
var rect = canvas.getBoundingClientRect();
lastX = (touch.clientX - rect.left - translateX) / scale; // 修改这里
lastY = (touch.clientY - rect.top - translateY) / scale; // 修改这里
ctx.beginPath();
ctx.moveTo((touch.clientX - rect.left) / scale, (touch.clientY - rect.top) / scale);
isTwoFingerTouch = false;
}
}
// 双指触摸移动
function handleTouchMove(event) {
if (isTwoFingerTouch) {
event.preventDefault();
var touch1 = event.touches[0];
var touch2 = event.touches[1];
var currentDistance = getDistance(touch1, touch2);
var newScale = (currentDistance / initialDistance) * initialScale;
scale = newScale;
canvasContainer.style.transform = "scale(" + scale + ")";
// 计算画布平移的位置
var deltaX = touch1.clientX - touch2.clientX;
var deltaY = touch1.clientY - touch2.clientY;
translateX = initialTranslateX + (deltaX / scale); // 修改这里
translateY = initialTranslateY + (deltaY / scale); // 修改这里
canvasContainer.style.transform += " translate(" + translateX + "px," + translateY + "px)";
} else if (drawing && !isTwoFingerTouch) {
var touch = event.touches[event.touches.length - 1];
var rect = canvas.getBoundingClientRect();
var currentX = (touch.clientX - rect.left - translateX) / scale; // 修改这里
var currentY = (touch.clientY - rect.top - translateY) / scale; // 修改这里
ctx.lineTo((touch.clientX - rect.left) / scale, (touch.clientY - rect.top) / scale);
ctx.strokeStyle = color;
ctx.lineWidth = size;
ctx.lineCap = "round";
ctx.lineJoin = "round";
ctx.stroke();
steps.push({
fromX: lastX,
fromY: lastY,
toX: currentX,
toY: currentY,
color: color,
size: size
});
lastX = currentX;
lastY = currentY;
}
}
function handleTouchEnd(event) {
if (event.touches.length < 2) {
event.preventDefault();
}
}
// 鼠标事件处理
canvas.addEventListener("mousedown", startDrawing);
canvas.addEventListener("mousemove", draw);
canvas.addEventListener("mouseup", stopDrawing);



// 计算两点之间的距离
function getDistance(point1, point2) {
var dx = point1.clientX - point2.clientX;
var dy = point1.clientY - point2.clientY;
return Math.sqrt(dx * dx + dy * dy);
}

// 改变画笔颜色
function changeColor(newColor) { color = newColor; }

// 改变画笔粗细
function changeSize(newSize) { size = newSize; }

// 开始绘画
function startDrawing(event) {
steps.splice(0, steps.length);
drawing = true;
if (event.type === "mousedown") {
var rect = canvas.getBoundingClientRect();
lastX = (event.clientX - rect.left) / scale;
lastY = (event.clientY - rect.top) / scale;
ctx.beginPath();
ctx.moveTo((event.clientX - rect.left) / scale, (event.clientY - rect.top) / scale);
} else if (event.type === "touchstart") {
var touch = event.touches[0];
var rect = canvas.getBoundingClientRect();
ctx.beginPath();
ctx.moveTo((touch.clientX - rect.left) / scale, (touch.clientY - rect.top) / scale);
}
}

// 绘画
function draw(event) {
if (!drawing) return;
if (event.type === "mousemove") {
var rect = canvas.getBoundingClientRect();
var currentX = (event.clientX - rect.left) / scale;
var currentY = (event.clientY - rect.top) / scale;
ctx.lineTo((event.clientX - rect.left) / scale, (event.clientY - rect.top) / scale);
ctx.strokeStyle = color;
ctx.lineWidth = size;
ctx.lineCap = "round";
ctx.lineJoin = "round";
ctx.stroke();
steps.push({
fromX: lastX,
fromY: lastY,
toX: currentX,
toY: currentY,
color: color,
size: size
});
lastX = currentX;
lastY = currentY;
} else if (event.type === "touchmove") {
var touch = event.touches[0];
var rect = canvas.getBoundingClientRect();
ctx.lineTo((touch.clientX - rect.left) / scale, (touch.clientY - rect.top) / scale);
}
}
// 重置画布位置

function resetCanvasPosition() {
  translateX = initialTranslateX;
  translateY = initialTranslateY;
  scale = initialScale; // 重置缩放比例
  canvasContainer.style.transform = `scale(${scale}) translate(${translateX}px, ${translateY}px)`;
  document.getElementById("size-slider").style.transform = `scale(${1 / scale})`;
}

// 停止绘画
function stopDrawing() { drawing = false; }

// 清空画布
function clearCanvas() {
ctx.clearRect(0, 0, canvas.width, canvas.height);
steps.splice(0, steps.length);
deletedSteps.splice(0, deletedSteps.length);
}

// 缩放画布
function zoomIn() {
scale *= 1.2; // 放大 20%
canvasContainer.style.transform = "scale(" + scale + ")";
canvasContainer.style.transformOrigin = "center top";
document.getElementById("size-slider").style.transform = "scale(" + (1 / scale) + ")"; // 添加此行
}

function zoomOut() {
scale /= 1.2; // 缩小 20%
canvasContainer.style.transform = "scale(" + scale + ")";
canvasContainer.style.transformOrigin = "center top";
document.getElementById("size-slider").style.transform = "scale(" + (1 / scale) + ")"; // 添加此行
}

function undo() {
if (steps.length > 0) {
var lastStep = steps.pop();
ctx.clearRect(0, 0, canvas.width, canvas.height);
for (var i = 0; i < steps.length; i++) {
ctx.beginPath();
ctx.moveTo(steps[i].fromX, steps[i].fromY);
ctx.lineTo(steps[i].toX, steps[i].toY);
ctx.strokeStyle = steps[i].color;
ctx.lineWidth = steps[i].size;
ctx.lineCap = "round";
ctx.lineJoin = "round";
ctx.stroke();
}
deletedSteps.push(lastStep);
}
}

function redo() {
if (deletedSteps.length > 0) {
var lastStep = deletedSteps.pop();
ctx.beginPath();
ctx.moveTo(lastStep.fromX, lastStep.fromY);
ctx.lineTo(lastStep.toX, lastStep.toY);
ctx.strokeStyle = lastStep.color;
ctx.lineWidth = lastStep.size;
ctx.lineCap = "round";
ctx.lineJoin = "round";
ctx.stroke();
steps.push(lastStep);
}
}
// 保存画布
function saveCanvas() {
var link = document.createElement('a');
link.download = 'canvas.png';
link.href = canvas.toDataURL()
link.click();
}
// 监听窗口大小变化
window.addEventListener('resize', updateCanvasSize);

// 初始调用一次
function updateCanvasSize() {
  // ...
  initialTranslateX = translateX;
  initialTranslateY = translateY;
  // ...
}
</script>
</body>
</html>