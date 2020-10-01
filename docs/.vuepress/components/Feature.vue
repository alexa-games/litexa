<template>
  <div class="feature home-aligned">
    <div class="feature-text">
      <h2>{{$attrs['title']}}</h2>
      <slot name="description"></slot>
      <div class="feature-buttons">
        <router-link class="nav-link" :to="$attrs['link']">
          <span>{{$attrs['link-text']}}</span>&nbsp;
          <span class="arrow">→</span>
        </router-link>
      </div>
    </div>
    <div class="feature-callout">
      <slot name="code"></slot>
    </div>
  </div>
</template>

<script>
export default {
  computed: {},
};
</script>

<style lang="stylus">
.feature {
  flex-grow: 1;
  flex-basis: 100%;
  max-width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 2rem;
  padding: 1em;

  .feature-text {
    flex-basis: 45%;
    min-width: 20em;
    max-width: 500px;
    padding: 30px;
    z-index: 2;
  }

  &:last-child {
    border-bottom: 0px solid rgba(0, 0, 0, 0.05);
  }

  &:nth-child(odd) {
    .feature-text {
      order: 3;
    }
  }

  h2 {
    font-size: 2rem;
    font-weight: 500;
    border-bottom: none;
    padding-bottom: 0;
    margin-top: -20px;
  }

  p {
    color: $textColor;
    font-size: 1.2rem;
  }

  .feature-callout {
    flex-basis: 45%;
    background-color: $thirdAccentColor;
    box-sizing: border-box;
    margin: 2em;
    z-index: 3;
    border-radius: 20px;
    box-shadow: 5px 5px 20px 5px #c3cfd6;
    overflow: hidden;

    div[class*='language-'] {
      background-color: #fff;
      margin-top: 30px;
      margin-bottom: 0;
      border-radius: 0 0 6px 6px;

      &:not(:first-child) {
        margin-top: 10px;
      }

      pre[class*='language-'] {
        margin: 0;

        code {
          color: #333;

          .token.string {
            color: #090;
          }

          .token.keyword {
            color: #a09;
          }

          .token.constant, .token.property {
            color: #a70;
          }

          .token.comment {
            color: #999;
          }
        }
      }
    }
  }
}

.features {
  padding: 0;
  margin-top: 2.5rem;
}

.feature-buttons {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  padding-top: 10px;

  .nav-link {
    font-weight: 300;
    font-size: 1.2rem;
    color: $textColor;

    &:hover {
      text-decoration: underline;
      color: $accentColor;
    }

    .arrow {
      color: $accentColor;
    }
  }
}

@media (max-width: $MQNarrow) {
  .home {
    .features {
      flex-direction: column;
    }

    .feature {
      flex-direction: column;
      max-width: 100%;

      .feature-callout {
        width: 100%;
        margin: 1rem 0;
        flex-basis: 50%;

        div[class*='language-'] {
          margin: 30px 0 0 0;
          padding: 0;

          &:not(:first-child) {
            margin-top: 10px;
          }
        }
      }

      .feature-text {
        order: 1;
      }
    }
  }
}
</style>