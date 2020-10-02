<template>
  <main class="home" aria-labelledby="main-title">
    <Clouds />

    <header class="hero">
      <img v-if="data.heroImage" :src="$withBase(data.heroImage)" :alt="data.heroAlt || 'hero'" />

      <h1 v-if="data.heroText !== null" id="main-title">{{ data.heroText || $title || 'Hello' }}</h1>

      <p v-html="data.tagline" v-if="data.tagline !== null" class="description"></p>

      <p v-if="data.actionText && data.actionLink" class="action">
        <NavLink class="action-button" :item="actionLink" />
      </p>
    </header>

    <Content class="theme-default-content custom" />

    <div v-if="data.footer" class="footer">{{ data.footer }}</div>
  </main>
</template>


<script>
import NavLink from "@theme/components/NavLink.vue";
export default {
  name: "Home",
  components: { NavLink },
  computed: {
    data() {
      return this.$page.frontmatter;
    },
    actionLink() {
      return {
        link: this.data.actionLink,
        text: this.data.actionText,
      };
    },
  },
};
</script>


<style lang="stylus">
.home {
  padding: $navbarHeight 0;
  margin: 0px auto;
  display: block;
  background: linear-gradient(to bottom, #fff 2%, #E1F3FC 51%, #fff 100%);
  background-size: 100% 70%;
  background-repeat: no-repeat;

  .home-aligned {
    max-width: 960px;
    margin: 0px auto;
  }

  h2 {
    border: 0;
  }

  .stripe {
    color: #fff;
    padding: 2rem;
    background-color: $accentColor;
    position: relative;
    z-index: 2;

    h2 {
      text-align: center;
      margin: 0;
      padding: 0 0 0.5rem 0;
      font-size: 200%;
    }

    div[class*='language-'] {
      max-width: 42rem;
      margin: 0 auto;
      border-radius: 0 0 6px 6px;
    }
  }

  div {
    position: relative;
  }

  .hero {
    text-align: center;
    position: relative;

    img {
      max-width: 100%;
      max-height: 280px;
      display: block;
      margin: 3rem auto 1.5rem;
    }

    h1 {
      font-size: 3.5rem;
      font-weight: 600;
      letter-spacing: 2px;
    }

    h1, .description, .action {
      margin: 1.8rem auto;
    }

    .description {
      max-width: 35rem;
      font-size: 1.6rem;
      line-height: 1.3;
      font-weight: 300;
      color: lighten($textColor, 10%);
    }

    .action-button {
      display: inline-block;
      font-size: 1.8rem;
      color: #fff;
      background-color: $accentColor;
      padding: 0.4rem 2rem;
      border-radius: 8px;
      transition: background-color 0.1s ease;
      box-sizing: border-box;
      border-bottom: 1px solid darken($accentColor, 10%);
      box-shadow: 5px 5px 10px 2px #90d6ff;

      &:hover {
        background-color: lighten($accentColor, 10%);
      }
    }
  }

  .footer {
    padding: 2.5rem;
    border-top: 1px solid $borderColor;
    text-align: center;
    color: lighten($textColor, 25%);
  }
}

@media (max-width: $MQNarrow) {
  .home {
    .description {
      font-size: 1.2rem;
      padding: 1em;
    }
  }
}

@media (max-width: $Narrow) {
  .home {
    padding: 0;

    .hero {
      img {
        max-height: 210px;
        margin: 2rem auto 1.2rem;
      }

      h1 {
        font-size: 2rem;
      }

      h1, .description, .action {
        margin: 1.2rem auto;
      }

      .description {
        font-size: 1.2rem;
      }

      .action-button {
        font-size: 1rem;
        padding: 0.6rem 1.2rem;
      }
    }

    .feature {
      h2 {
        font-size: 1.25rem;
      }
    }
  }
}
</style>