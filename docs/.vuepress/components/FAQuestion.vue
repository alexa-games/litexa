<template>
  <div class="faquestion">
    <slot />
  </div>
</template>

<style lang="stylus">
.faquestions {
  max-width: 1280px;
  padding: 1.2rem 2rem;
  margin: 2.5rem auto;
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  align-content: stretch;
  background: #fff;
  justify-content: space-between;
}

.faquestion {
  box-sizing: content-box;
  flex-grow: 1;
  flex-basis: 30%;
  background-color: #fff;
  padding: 1em;
  min-width: 200px;
  margin: 0px 0px 20px 0px;

  @media (max-width: ($MQMobile + 1px)) {
    min-width: 75%;
    min-height: 250px;
  }

  img {
    width: 135px;
    margin: 0 auto;
    display: block;
  }

  h2 {
    height: 4em;
    position: relative;
    font-size: 1.6rem;
    font-weight: 500;
    border: none;
    padding: 0;
    margin: 0;
    color: lighten($textColor, 10%);
    vertical-align: bottom;
    display: table-cell;
  }

  p {
    color: lighten($textColor, 25%);
  }
}

@media (max-width: $MQNarrow) {
  .home {
    .faquestion {
      max-width: 100%;
      margin: 0;
      height: auto;
      min-height: auto;

      h2 {
        height: auto;
        display: block;
      }
    }
  }
}
</style>