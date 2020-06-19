<template>
  <div class="feature-card">
    <img v-if="$attrs.image" :src="$withBase($attrs.image)" alt />
    <slot />
  </div>
</template>

<style lang="stylus">
.feature-cards {
  padding: 1.2rem 0;
  margin-top: 2.5rem;
  margin-bottom: 2.5rem;
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  align-content: stretch;
  justify-content: center;
}

.feature-card {
  box-sizing: border-box;
  flex-grow: 1;
  flex-basis: 30%;
  background-color: #fff;
  border-radius: 20px;
  box-shadow: 5px 5px 20px 5px #c3cfd6;
  padding: 2em 2em 1em 2em;
  margin: 1%;
  min-width: 15em;
  min-height: 450px;
  z-index: 2;

  img {
    width: 135px;
    margin: 0 auto;
    display: block;
  }

  h2 {
    font-size: 1.6rem;
    text-align: center;
    font-weight: 500;
    border-bottom: none;
    padding-bottom: 0;
    color: lighten($textColor, 10%);
  }

  p {
    color: lighten($textColor, 25%);
  }
}

@media (max-width: $MQNarrow) {
  .feature-card {
    max-width: 100%;
    min-height: inherit;
    margin: 1em;
  }
}
</style>