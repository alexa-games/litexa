<template>
  <div class="cloud-herd">
    <div class="cloud-container cloud-fluffy"></div>
    <div class="cloud-container cloud-fade cloud-charlie"></div>
    <div class="cloud-container cloud-fade cloud-twins"></div>
    <div class="cloud-container cloud-righty"></div>
    <div class="cloud-container cloud-bottoms"></div>
    <div class="cloud-container cloud-left-twins"></div>
    <div class="cloud-container cloud-bottom-left"></div>
    <div class="cloud-container cloud-fluffy"></div>
    <div class="cloud-container cloud-fade cloud-charlie"></div>
    <div class="cloud-container cloud-fade cloud-twins"></div>
    <div class="cloud-container cloud-righty"></div>
    <div class="cloud-container cloud-bottoms"></div>
    <div class="cloud-container cloud-left-twins"></div>
    <div class="cloud-container cloud-bottom-left"></div>
  </div>
</template>

<style lang="stylus">
div.cloud-charlie {
  // cloud-goin-left.svg base64 encoded
  background-image: url('data:image/svg+xml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHZpZXdCb3g9JzAgMCAyNDQgMTM0Ljg3Jz48ZGVmcz48c3R5bGU+LmNsb3VkLTF7ZmlsbDojMDBjYWZmO29wYWNpdHk6MC4xNTt9PC9zdHlsZT48L2RlZnM+PGcgaWQ9J0xheWVyXzInIGRhdGEtbmFtZT0nTGF5ZXIgMic+PGcgaWQ9J0xheWVyXzEtMicgZGF0YS1uYW1lPSdMYXllciAxJz48cGF0aCBjbGFzcz0nY2xvdWQtMScgZD0nTTAsOTIuNjNBNDEuNCw0MS40LDAsMCwxLDQxLjU1LDUxLjM5Yy43MiwwLDEuNDQsMCwyLjE1LjA3YTY3LjIyLDY3LjIyLDAsMCwxLDEzMi41NywxNmgwYTMzLjYsMzMuNiwwLDAsMSwzMy4wOCwzMmwxNywuMDZBMTcuNjksMTcuNjksMCwwLDEsMjQ0LDExNy4yNWgwYTE3LjY5LDE3LjY5LDAsMCwxLTE3Ljc1LDE3LjYybC0xOTAuNjctLjcyYTE3LjU3LDE3LjU3LDAsMCwxLTkuOTEtMy4wOEE0MS4zOSw0MS4zOSwwLDAsMSwwLDkyLjYzWicvPjwvZz48L2c+PC9zdmc+');
}

div.cloud-twins {
  background-image: url('data:image/svg+xml;base64, CjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTA5LjEzIDE0Ni42Ij48ZGVmcz48c3R5bGU+LmNscy0xLC5jbHMtMntmaWxsOm5vbmU7c3Ryb2tlOiMwMGNhZmY7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kO29wYWNpdHk6MC4xNTt9LmNscy0xe3N0cm9rZS13aWR0aDo2cHg7fS5jbHMtMntzdHJva2Utd2lkdGg6NXB4O308L3N0eWxlPjwvZGVmcz48dGl0bGU+QXNzZXQgMTg8L3RpdGxlPjxnIGlkPSJMYXllcl8yIiBkYXRhLW5hbWU9IkxheWVyIDIiPjxnIGlkPSJMYXllcl8xLTIiIGRhdGEtbmFtZT0iTGF5ZXIgMSI+PHBhdGggY2xhc3M9ImNscy0xIiBkPSJNNDYuNjgsMTE3LjcxYzYuNywwLDI1LjMyLTUuODcsMjUuMzItMjkuOTEsMC0xOC4yOS0xNS41My0zMi4zLTM0LjUtMzIuM0MxOC4wNSw1NS41LDMsNzAuNTEsMyw4OS4xOWMwLDI2LjM2LDI4LjYyLDMyLjE0LDI4LjYyLDMyLjE0cy01LjA5LDE1LjE5LDcuMDcsMTUuNzVTNDksMTIzLjI0LDQyLjgyLDEyNi4yNnMtMy42OCwxOC4yOSw5LjM3LDE3LjI5Ii8+PHBhdGggY2xhc3M9ImNscy0yIiBkPSJNOTQuMDYsMzMuMzljMy4zMiwwLDEyLjU3LTIuOTIsMTIuNTctMTQuODYsMC05LjA3LTcuNzEtMTYtMTcuMTMtMTZBMTYuNzgsMTYuNzgsMCwwLDAsNzIuMzcsMTkuMjJjMCwxMy4wOSwxNC4yMSwxNiwxNC4yMSwxNlM4NC4wNSw0Mi43Miw5MC4wOSw0M3M1LjEtNi44NywyLTUuMzctMS44Myw5LjA4LDQuNjUsOC41OCIvPjwvZz48L2c+PC9zdmc+');
}

div.cloud-left-twins {
  background-image: url('data:image/svg+xml;base64, CjxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMjcxLjM1IDI5MC4xMyI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOm5vbmU7c3Ryb2tlOiMwMGNhZmY7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kO3N0cm9rZS13aWR0aDo5cHg7b3BhY2l0eTowLjE1O308L3N0eWxlPjwvZGVmcz48dGl0bGU+QXNzZXQgMTc8L3RpdGxlPjxnIGlkPSJMYXllcl8yIiBkYXRhLW5hbWU9IkxheWVyIDIiPjxnIGlkPSJMYXllcl8xLTIiIGRhdGEtbmFtZT0iTGF5ZXIgMSI+PHBhdGggY2xhc3M9ImNscy0xIiBkPSJNMjA5LjczLDI1MS43OWMtOC43NSwwLTMzLjEtNy42OC0zMy4xLTM5LjEyLDAtMjMuOTEsMjAuMzEtNDIuMjMsNDUuMTEtNDIuMjMsMjUuNDMsMCw0NS4xMSwxOS42Myw0NS4xMSw0NCwwLDM0LjQ3LTM3LjQzLDQyLTM3LjQzLDQyczYuNjYsMTkuODctOS4yNCwyMC41OVMyMDYuNzYsMjU5LDIxNC43OCwyNjNzNC44MiwyMy45My0xMi4yNSwyMi42MiIvPjxwYXRoIGNsYXNzPSJjbHMtMSIgZD0iTTcxLjMsMTY4LjY1Yy0xNy42NiwwLTY2LjgtMTUuNS02Ni44LTc4Ljk0LDAtNDguMjQsNDEtODUuMjEsOTEtODUuMjEsNTEuMzEsMCw5MSwzOS42MSw5MSw4OC44OCwwLDY5LjU0LTc1LjUyLDg0LjgxLTc1LjUyLDg0LjgxczEzLjQzLDQwLjA4LTE4LjY1LDQxLjU1LTI3LjA5LTM2LjUtMTAuOS0yOC41Niw5LjcyLDQ4LjI4LTI0LjcyLDQ1LjYzIi8+PC9nPjwvZz48L3N2Zz4=');
}

div.cloud-fluffy {
  background-image: url('data:image/svg+xml;base64, PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MzIgMjkzLjUxIj48ZGVmcz48c3R5bGU+LmNscy0xe2ZpbGw6I2ZmZjt9PC9zdHlsZT48L2RlZnM+PGcgaWQ9IkxheWVyXzIiIGRhdGEtbmFtZT0iTGF5ZXIgMiI+PGcgaWQ9IkxheWVyXzEtMiIgZGF0YS1uYW1lPSJMYXllciAxIj48cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Ik01MzIsMjAyLjM4YTkwLjIzLDkwLjIzLDAsMCwwLTkwLjM5LTkwLjA2Yy0xLjU4LDAtMy4xNCwwLTQuNy4xM2ExNDYuNTMsMTQ2LjUzLDAsMCwwLTI4OSwzNC4zNHYwQTczLjI2LDczLjI2LDAsMCwwLDc1LjYsMjE2LjMzbC0zNy4xMS4wNkEzOC41NiwzOC41NiwwLDAsMCwwLDI1NUgwYTM4LjU2LDM4LjU2LDAsMCwwLDM4LjYzLDM4LjQ5bDQxNS42NC0uNzdhMzguMzksMzguMzksMCwwLDAsMjEuNjEtNi42NkE5MC4yNSw5MC4yNSwwLDAsMCw1MzIsMjAyLjM4WiIvPjwvZz48L2c+PC9zdmc+');
}

div.cloud-righty {
  background-image: url('data:image/svg+xml;base64, PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDc4LjE1IDcyMC4yNSI+PGRlZnM+PHN0eWxlPi5jbHMtMXtmaWxsOiMwMGNhZmY7b3BhY2l0eTowLjE1O30uY2xzLTIsLmNscy00e2ZpbGw6I2ZmZjt9LmNscy0ze2ZpbGw6IzVjZWFkOTtvcGFjaXR5OjAuMjt9LmNscy0zLC5jbHMtNHtmaWxsLXJ1bGU6ZXZlbm9kZDt9PC9zdHlsZT48L2RlZnM+PGcgaWQ9IkxheWVyXzIiIGRhdGEtbmFtZT0iTGF5ZXIgMiI+PGcgaWQ9IkxheWVyXzEtMiIgZGF0YS1uYW1lPSJMYXllciAxIj48cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Ik0xMDAwLDEzMS40M2E1OC43Miw1OC43MiwwLDAsMC01OC45NS01OC41Yy0xLDAtMiwwLTMuMDUuMDlBOTUuMzgsOTUuMzgsMCwwLDAsNzQ5LjkyLDk1LjczdjBBNDcuNjgsNDcuNjgsMCwwLDAsNzAzLDE0MS4wOWwtMjQuMTYuMDlhMjUuMDksMjUuMDksMCwwLDAtMjUsMjUuMTloMGEyNS4xLDI1LjEsMCwwLDAsMjUuMTksMjVsMjcwLjU1LTFBMjQuOSwyNC45LDAsMCwwLDk2My42MSwxODYsNTguNzMsNTguNzMsMCwwLDAsMTAwMCwxMzEuNDNaIi8+PHBhdGggY2xhc3M9ImNscy0yIiBkPSJNNjM5LjM3LDI0NC4ybC0zNy4xMi0uMDdBNzMuMjgsNzMuMjgsMCwwLDAsNTMwLDE3NC42djBhMTQ2LjU2LDE0Ni41NiwwLDAsMC0yODkuMS0zNC4zNGMtMS41Ni0uMDktMy4xMi0uMTMtNC43LS4xNGE5MC4yNyw5MC4yNywwLDAsMC04Ni43MiwxMTUuODIsMTA1LjMxLDEwNS4zMSwwLDAsMC04MS4yLDc4LjU3Yy0xLjExLS4wNi0yLjI0LS4wOS0zLjM3LS4wOUE2NC43Niw2NC43NiwwLDAsMCw0MC4yOSw0NTkuMTJhMjcuNTIsMjcuNTIsMCwwLDAsMTUuNSw0Ljc5bDI5OC4zNS41NWEyNy42NywyNy42NywwLDAsMCwyNy43Mi0yNy42M2gwYTI3LjY3LDI3LjY3LDAsMCwwLTI3LjYyLTI3LjcybC0yNi42NC0uMDVhNTIuNTgsNTIuNTgsMCwwLDAtNTEuODctNDkuOXYwYTEwNS4xMiwxMDUuMTIsMCwwLDAtNy4xOS0zOC40OWwzNzAuNjkuNjhhMzguNTYsMzguNTYsMCwwLDAsMzguNjQtMzguNDloMEEzOC41OCwzOC41OCwwLDAsMCw2MzkuMzcsMjQ0LjJaIi8+PHBhdGggY2xhc3M9ImNscy0yIiBkPSJNOTc5Ljc3LDY2Ni42MmE1My42LDUzLjYsMCwwLDAtNTMuNi01My42Yy0uOTQsMC0xLjg3LDAtMi43OS4wOGE4Ny4wNSw4Ny4wNSwwLDAsMC0xNzEuNzUsMjAuMWgwYTQzLjUzLDQzLjUzLDAsMCwwLTQzLDQxLjIzaC0yMmEyMi45LDIyLjksMCwwLDAtMjIuOSwyMi45MWgwYTIyLjksMjIuOSwwLDAsMCwyMi45LDIyLjlsMjQ2LjkyLDBhMjIuOCwyMi44LDAsMCwwLDEyLjg1LTMuOTRBNTMuNTksNTMuNTksMCwwLDAsOTc5Ljc3LDY2Ni42MloiLz48cGF0aCBjbGFzcz0iY2xzLTIiIGQ9Ik0xMDc4LjE1LDQ4NC42MmEyOS45MiwyOS45MiwwLDAsMC0zMC0yOS44NmMtLjUyLDAtMSwwLTEuNTYsMGE0OC41OCw0OC41OCwwLDAsMC05NS44MywxMS4zOWgwYTI0LjI4LDI0LjI4LDAsMCwwLTI0LDIzLjA1bC0xMi4zMSwwYTEyLjc5LDEyLjc5LDAsMCwwLTEyLjc2LDEyLjgxaDBhMTIuNzksMTIuNzksMCwwLDAsMTIuODEsMTIuNzZsMTM3LjgxLS4yNmExMi42OSwxMi42OSwwLDAsMCw3LjE2LTIuMjFBMjkuOTMsMjkuOTMsMCwwLDAsMTA3OC4xNSw0ODQuNjJaIi8+PHBhdGggY2xhc3M9ImNscy0zIiBkPSJNOTA5LjkxLDM0Ny41M2E0OSw0OSwwLDAsMS0zNC42NCw0Ni45MWMtMy45NSwxLjMtNC44NSwyLjI4LTQuODUsNS4zNnYxNC4yNmExLjY0LDEuNjQsMCwwLDEtMi4zNywxLjY3cy00OS4xNC0yMS4xNS01NS4xMi02MC42N2MwLS4yLDAtLjM5LS4wNy0uNTktLjA3LS40NC0uMTMtLjg3LS4xNy0xLjMycy0uMDktLjc3LS4xMy0xLjE2YzAtLjE3LDAtLjM1LDAtLjUzLDAtLjU2LS4wOC0xLjEyLS4xMi0yLjEsMC0uNjEsMC0xLjIxLDAtMS44M2E0OC44OCw0OC44OCwwLDAsMSw0Ny40NC00OSwyNy43NiwyNy43NiwwLDAsMCwxOS4wNSwyMWMyLjI0Ljc0LDIuNzYsMS4zLDIuNzYsM3Y4LjA4YS45My45MywwLDAsMCwxLjM1Ljk0LDcyLjE3LDcyLjE3LDAsMCwwLDE4LjE5LTEyLjA2QTQ4LjkyLDQ4LjkyLDAsMCwxLDkwOS45MSwzNDcuNTNaIi8+PHBhdGggY2xhc3M9ImNscy00IiBkPSJNOTE0LjUsMjkyLjk0YzAsLjM1LDAsLjY5LDAsMSwwLC41NSwwLC44Ny0uMDYsMS4xOCwwLC4xMSwwLC4yMSwwLC4zMXMwLC40NC0uMDYuNjYtLjA2LjUtLjEuNzRhMi4xNSwyLjE1LDAsMCwxLS4wNS4zNGMtMS4zOSw5LjI1LTcsMTYuNzItMTMsMjIuM2E0OC42NCw0OC42NCwwLDAsMC00MC0yMWwtMS4zMywwYTI4LjA5LDI4LjA5LDAsMCwxLS41Ny01LjYxLDI3LjY0LDI3LjY0LDAsMSwxLDU1LjI3LDBaIi8+PC9nPjwvZz48L3N2Zz4=');
}

div.cloud-bottoms {
  background-image: url('data:image/svg+Xml;base64, PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0MzcuNTQgOTA0LjYiPjxkZWZzPjxzdHlsZT4uY2xzLTEsLmNscy0ze2ZpbGw6IzAwY2FmZjt9LmNscy0xe29wYWNpdHk6MC4xNTt9LmNscy0ye2ZpbGw6IzVjZWFkOTt9LmNscy0yLC5jbHMtMywuY2xzLTR7ZmlsbC1ydWxlOmV2ZW5vZGQ7fS5jbHMtMiwuY2xzLTN7b3BhY2l0eTowLjI7fS5jbHMtNHtmaWxsOiNmZmY7fTwvc3R5bGU+PC9kZWZzPjxnIGlkPSJMYXllcl8yIiBkYXRhLW5hbWU9IkxheWVyIDIiPjxnIGlkPSJMYXllcl8xLTIiIGRhdGEtbmFtZT0iTGF5ZXIgMSI+PHBhdGggY2xhc3M9ImNscy0xIiBkPSJNMCw4NzIuMzZjLjA3LTE3LjQ0LDE0LjUyLTMxLjUyLDMyLjI4LTMxLjQ1LjU3LDAsMS4xMiwwLDEuNjguMDUsNS41Mi0yMi41OSwyNi4yOC0zOS4zNCw1MS0zOS4yNSwyOC44NS4xMSw1Mi4xNCwyMy4xNSw1Miw1MS40N2gwYTI1LjksMjUuOSwwLDAsMSwyNS43MSwyNC4zN2wxMy4yMy4wNWExMy42MywxMy42MywwLDAsMSwxMy43LDEzLjU1aDBhMTMuNjMsMTMuNjMsMCwwLDEtMTMuOCwxMy40NEwyNy42NSw5MDRhMTMuODYsMTMuODYsMCwwLDEtNy43LTIuMzVBMzEuNTksMzEuNTksMCwwLDEsMCw4NzIuMzZaIi8+PHBhdGggY2xhc3M9ImNscy0yIiBkPSJNMTQ0LjUyLDI2N2E3Ny42OSw3Ny42OSwwLDAsMCw1NC44OS03NC4zNWMwLTQyLjktMzQuNjEtNzcuNjctNzcuMzEtNzcuNjdzLTc3LjMyLDM0Ljc3LTc3LjMyLDc3LjY3YzAsMSwwLDEuOTMuMDYsMi45LjA3LDEuNTQuMTIsMi40My4xOSwzLjMyLDAsLjI4LDAsLjU2LjA3Ljg0LjA2LjYyLjEyLDEuMjMuMTksMS44NHMuMTgsMS40LjI3LDIuMDljMCwuMzEuMDguNjMuMTMuOTQsOS40Nyw2Mi42NSw4Ny4zNiw5Ni4xNiw4Ny4zNiw5Ni4xNmEyLjYxLDIuNjEsMCwwLDAsMy43Ny0yLjYzVjI3NS41MUMxMzYuODIsMjcwLjY0LDEzOC4yNSwyNjkuMDgsMTQ0LjUyLDI2N1oiLz48cGF0aCBjbGFzcz0iY2xzLTMiIGQ9Ik0xNzMuMDUsNzQuNDRBMzgsMzgsMCwxLDEsMjIxLjg4LDM4YzAsLjQ4LDAsLjk1LDAsMS40MiwwLC43Ni0uMDYsMS4xOS0uMDksMS42MywwLC4xNCwwLC4yNywwLC40MSwwLC4zMS0uMDYuNi0uMS45cy0uMDguNjktLjEzLDFsLS4wNi40N0MyMTYuOCw3NC41NSwxNzguNjYsOTEsMTc4LjY2LDkxYTEuMjcsMS4yNywwLDAsMS0xLjg0LTEuMjlWNzguNkMxNzYuODEsNzYuMjEsMTc2LjExLDc1LjQ1LDE3My4wNSw3NC40NFoiLz48cGF0aCBjbGFzcz0iY2xzLTQiIGQ9Ik0yMzMuNDQsMTU2LjczYTIzLjkyLDIzLjkyLDAsMSwxLDMwLjc0LTIyLjkyYzAsLjMsMCwuNiwwLC45LDAsLjQ3LDAsLjc1LS4wNiwxLDAsLjA5LDAsLjE4LDAsLjI2bC0uMDYuNTdjMCwuMjIsMCwuNDMtLjA4LjY0czAsLjIsMCwuMjlDMjYxLDE1Ni44LDIzNywxNjcuMTIsMjM3LDE2Ny4xMmEuOC44LDAsMCwxLTEuMTYtLjgxdi03QzIzNS44MSwxNTcuODQsMjM1LjM3LDE1Ny4zNiwyMzMuNDQsMTU2LjczWiIvPjxwYXRoIGNsYXNzPSJjbHMtMSIgZD0iTTQzNy41Myw2OTIuNDFjLS4xNC0zOC40MS0zMi02OS40My03MS4xMS02OS4yOC0xLjI0LDAtMi40NywwLTMuNjkuMTEtMTIuMTgtNDkuNzctNTcuOS04Ni42Ny0xMTIuMy04Ni40Ny02My41NS4yNC0xMTQuODgsNTEtMTE0LjY0LDExMy4zOHYwYy0zMC40OC40Mi01NS4xOSwyNC4wOC01Ni42NCw1My43TDUwLDcwNGMtMTYuNzIuMDYtMzAuMjMsMTMuNDItMzAuMTcsMjkuODRoMGMuMDYsMTYuNDEsMTMuNjcsMjkuNjcsMzAuMzksMjkuNmwzMjYuNDEtMS4yM0EzMC41LDMwLjUsMCwwLDAsMzkzLjU4LDc1N0M0MTkuNDYsNzQ2LjU4LDQzNy42NCw3MjEuNTYsNDM3LjUzLDY5Mi40MVoiLz48L2c+PC9nPjwvc3ZnPg==');
}

div.cloud-bottom-left {
  background-image: url('data:image/svg+Xml;base64, PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAzOTkuMzYgOTY2LjAzIj48ZGVmcz48c3R5bGU+LmNscy0xLC5jbHMtM3tmaWxsOiNmZmY7fS5jbHMtMntmaWxsOiM1Y2VhZDk7b3BhY2l0eTowLjE1O30uY2xzLTIsLmNscy0ze2ZpbGwtcnVsZTpldmVub2RkO308L3N0eWxlPjwvZGVmcz48ZyBpZD0iTGF5ZXJfMiIgZGF0YS1uYW1lPSJMYXllciAyIj48ZyBpZD0iTGF5ZXJfMS0yIiBkYXRhLW5hbWU9IkxheWVyIDEiPjxwYXRoIGNsYXNzPSJjbHMtMSIgZD0iTTk0Ljc5LDkxNC4zNWE1MS42NSw1MS42NSwwLDAsMSw1MS42NS01MS42NGMuOSwwLDEuOCwwLDIuNjkuMDdhODMuODgsODMuODgsMCwwLDEsMTY1LjQ5LDE5LjM3aDBhNDIsNDIsMCwwLDEsNDEuNDMsMzkuNzNoMjEuMjRBMjIuMDcsMjIuMDcsMCwwLDEsMzk5LjM2LDk0NGgwQTIyLjA3LDIyLjA3LDAsMCwxLDM3Ny4yOSw5NjZsLTIzNy45MiwwQTIyLDIyLDAsMCwxLDEyNyw5NjIuMjEsNTEuNjcsNTEuNjcsMCwwLDEsOTQuNzksOTE0LjM1WiIvPjxwYXRoIGNsYXNzPSJjbHMtMSIgZD0iTTAsNzM5YTI4LjgyLDI4LjgyLDAsMCwxLDI4Ljg4LTI4Ljc3Yy41LDAsMSwwLDEuNSwwYTQ2LjgxLDQ2LjgxLDAsMCwxLDkyLjM0LDExaDBhMjMuMzksMjMuMzksMCwwLDEsMjMuMDgsMjIuMjFsMTEuODYsMEExMi4zMiwxMi4zMiwwLDAsMSwxNzAsNzU1LjgxaDBhMTIuMzEsMTIuMzEsMCwwLDEtMTIuMzQsMTIuMjlsLTEzMi43OS0uMjRhMTIuMjIsMTIuMjIsMCwwLDEtNi45LTIuMTNBMjguODUsMjguODUsMCwwLDEsMCw3MzlaIi8+PHBhdGggY2xhc3M9ImNscy0yIiBkPSJNMTY5LjkxLDgyLjdjMCwxLDAsMi4wNi0uMDYsMy4wOS0uMDcsMS42NC0uMTQsMi41OC0uMiwzLjUzLDAsLjMxLS4wNi42LS4wOC45LS4wNi42Ny0uMTMsMS4zMS0uMiwycy0uMTksMS40OS0uMjksMi4yMmMwLC4zMy0uMDguNjctLjEzLDFhOTcuNDIsOTcuNDIsMCwwLDEtMTMuMywzNS45MiwzNy44MywzNy44MywwLDAsMC05LjE1LTEuMTEsMzguMjksMzguMjksMCwwLDAtMzguMiwzOC4zN2MwLC40OCwwLDEsMCwxLjQzLDAsLjc2LjA2LDEuMi4wOSwxLjY0LDAsLjE0LDAsLjI4LDAsLjQxLDAsLjMyLDAsLjYyLjA5Ljkxcy4wOC43LjEzLDFsLjA2LjQ3Yy4yMSwxLjM3LjQ5LDIuNzEuODIsNGEyMDguMywyMDguMywwLDAsMS0zMy4zLDE5LjI5Yy0yLjIxLjg0LTQtLjQxLTQtMi44VjE3MC45MWMwLTUuMTktMS41Mi02Ljg1LTguMTctOUE4Mi42OSw4Mi42OSwwLDAsMSw1Ljg1LDgyLjdDNS44NSwzNyw0Mi41OCwwLDg3Ljg4LDBTMTY5LjkxLDM3LDE2OS45MSw4Mi43WiIvPjxwYXRoIGNsYXNzPSJjbHMtMyIgZD0iTTE4NC43LDE2OC41OWEzOC4zNywzOC4zNywwLDAsMS0yNy4xMiwzNi43M2MtMy4xLDEtMy44LDEuNzktMy44LDQuMnYxMS4xN2ExLjI4LDEuMjgsMCwwLDEtMS44NiwxLjNzLTM1LjE1LTE1LjEyLTQyLjM0LTQzLjQ5YzE1LjgxLTExLjEsMzMuODctMjYuOSw0Ni4wOC00Ny4xN0EzOC4zNCwzOC4zNCwwLDAsMSwxODQuNywxNjguNTlaIi8+PC9nPjwvZz48L3N2Zz4=');
}

cloudScroll(speed, phase) {
  animation: flying (120s / speed) linear (phase * -120s / speed) infinite;
}

baloonBob(speed, phase) {
  animation: bobbing (20s / speed) ease-in-out (phase * -20s / speed) infinite;
}

@keyframes flying {
  0% {
    left: -20%;
    opacity: 0;
  }

  5% {
    left: -10%;
    opacity: 1;
  }

  95% {
    left: 90%;
    opacity: 0.8;
  }

  100% {
    left: 100%;
    opacity: 0;
  }
}

@keyframes bobbing {
  0% {
    transform: translate(0px, 0px);
  }

  20% {
    transform: translate(0px, -13px);
  }

  41% {
    transform: translate(1px, 11px);
  }

  61% {
    transform: translate(1px, -22px);
  }

  80% {
    transform: translate(0px, 10px);
  }

  100% {
    transform: translate(0px, 0px);
  }
}

.cloud-charlie {
  width: 195px;
  height: 106px;
  top: 100px;
  transition: all 4.3s ease;
  cloudScroll(0.6, 0);
}

.cloud-charlie ~ .cloud-charlie {
  top: 1730px;
}

.cloud-twins {
  width: 109px;
  height: 146px;
  right: 180px;
  top: 120px;
  transition: all 4.3s ease;
  baloonBob(0.4, 0);
}

.cloud-twins ~ .cloud-twins {
  top: 1820px;
}

.cloud-righty {
  width: 808px;
  height: 540px;
  top: 330px;
  transition: all 4.3s ease;
  cloudScroll(0.2, 0.6);
}

.cloud-righty ~ .cloud-righty {
  top: 1930px;
  cloudScroll(0.1, 0.3);
}

.cloud-bottoms {
  width: 324px;
  height: 1078px;
  right: 0px;
  top: 1020px;
  transition: all 4.3s ease;
  baloonBob(0.8, 0.5);
}

.cloud-bottoms ~ .cloud-bottoms {
  top: 2520px;
}

.cloud-bottom-left {
  width: 299px;
  height: 1024px;
  left: 20px;
  top: 730px;
  transition: all 4.3s ease;
  cloudScroll(0.12, 0.3);
}

.cloud-bottom-left ~ .cloud-bottom-left {
  top: 2430px;
}

.cloud-fluffy {
  width: 450px;
  height: 253px;
  left: -10px;
  top: 530px;
  transition: all 4.3s ease;
  cloudScroll(0.08, 0.1);
}

.cloud-fluffy ~ .cloud-fluffy {
  top: 1230px;
}

.cloud-left-twins {
  width: 216px;
  height: 232px;
  left: 180px;
  top: 220px;
  opacity: 0.7;
  transition: all 4.3s ease;
  baloonBob(0.8, 0.5);
}

.cloud-left-twins ~ .cloud-left-twins {
  top: 2220px;
  left: 100px;
}

.cloud-fade {
  opacity: 0.5;
}

.cloud-fade:hover {
  opacity: 1;
  -webkit-transform: scale(1.3);
  -ms-transform: scale(1.3);
  transform: scale(1.3);
}

div.cloud-herd {
  width: 100vw;
  height: 4000px;
  overflow: hidden;
  position: absolute;
  left: 0;
  top: 0;

  div.cloud-container {
    background-repeat: no-repeat;
    position: absolute;
    will-change: transform, opacity;

    @media (max-width: $MQMobile) {
      display: none;
    }
  }
}
</style>