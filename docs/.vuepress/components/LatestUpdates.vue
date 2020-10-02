<template>
  <div class="home-aligned">
    <div class="latest-updates">
      <h2>🔔 Latest Updates</h2>
      <slot />
      <div class="feature-buttons">
        <a class="nav-link" :href="$attrs.changeLogURL">
          <span>See all updates</span>&nbsp;
          <span class="arrow">→</span>
        </a>
      </div>
    </div>
  </div>
</template>

<style lang="stylus">
.latest-updates {
  box-sizing: border-box;
  // background-color: #fff;
  border-radius: 20px;
  box-shadow: 5px 5px 64px #fff inset;
  padding: 2em;
  min-width: 15em;
  z-index: 2;
  width: 90%;
  margin: 2em auto 2em auto;
  border-left: 2px solid #00c7bd;
  border-right: 2px solid #00c7bd;

  ul {
    margin: 0;
    list-style-type: '➕';
    list-style-type: none;

    li {
      padding-left: 2em;
      position: relative;
    }

    li:before {
      content: '＋';
      position: absolute;
      left: 0;
    }
  }

  div[class*='language-'] {
    background: #fff;
  }

  code {
    background: #fff;
  }

  h2 {
    margin: 0 0 0 0;
  }
}
</style>