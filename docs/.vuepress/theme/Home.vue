<template>
  <div class="home">
    <div class="home-aligned">
      <div v-if="data.heroImage || data.heroText" class="hero">
        <img v-if="data.heroImage" :src="$withBase(data.heroImage)" alt="hero">

        <h1>{{ data.heroText || $title || 'Hello' }}</h1>

        <p
          class="description"
          v-html="data.tagline || $description || 'Welcome to your VuePress site'"
        ></p>

        <p class="action" v-if="data.actionText && data.actionLink">
          <NavLink class="action-button" :item="actionLink"/>
        </p>
      </div>
      <div class="feature-content">
        <div class="features" v-if="data.features && data.features.length">
          <div class="feature" v-for="feature in data.features">
            <div class="feature-text">
              <h2 v-html="feature.title"></h2>
              <p v-html="feature.details"></p>
              <div v-if="feature.button" class="feature-buttons">
                <router-link
                  class="nav-link"
                  :to="feature.button.link"
                  :exact="feature.button.link === '/'"
                >
                  <span>{{feature.button.text?feature.button.text:'see more'}}</span>&nbsp;
                  <span class="arrow">→</span>
                </router-link>
              </div>
            </div>
            <div class="feature-callout">
              <div class="language-coffeescript extra-class">
                <pre class="language-coffeescript"><code><span class="intent">launch</span>
  say <span class="token string">"Hi there!"</span>
    <span class="token keyword">or</span> <span class="token string">"&lt;!Howdy.&gt;"</span>
    <span class="token keyword">or</span> <span class="token string">"Greetings, human."</span>
  say <span class="token string">"What's your name?"</span>

  <span class="token keyword">when</span> <span class="token string">"My name is $name"</span>
    <span class="token keyword">with</span> name <span class="token operator">=</span> <span class="token constant">AMAZON</span><span class="token punctuation">.</span><span class="token constant">US_FIRST_NAME</span>
    say <span class="token string">"Hey! nice to meet you, $name."</span>
    soundEffect happy<span class="token punctuation">.</span>mp3
</code></pre>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="minor-features" v-if="data.minorFeatures && data.minorFeatures.length">
        <div class="minor-feature" v-for="(feature, index) in data.minorFeatures" :key="index">
          <img v-if="feature.img" :src="$withBase(feature.img)" alt>
          <h2>{{ feature.title }}</h2>
          <p>{{ feature.details }}</p>
        </div>
      </div>



<div class="feature-content">
        <div class="features" v-if="data.secondaryFeatures && data.secondaryFeatures.length">
          <div class="feature" v-for="feature, key in data.secondaryFeatures">
            <div class="feature-text">
              <h2 v-html="feature.title"></h2>
              <p v-html="feature.details"></p>
              <div v-if="feature.button" class="feature-buttons">
                <router-link
                  class="nav-link"
                  :to="feature.button.link"
                  :exact="feature.button.link === '/'"
                >
                  <span>{{feature.button.text?feature.button.text:'see more'}}</span>&nbsp;
                  <span class="arrow">→</span>
                </router-link>
              </div>
            </div>
            <div class="feature-callout" v-if="key === 0">
              <div class="language-coffeescript extra-class">
<pre class="language-coffeescript"><code>askAboutRoses
  say <span class="token string">"Do you prefer red or blue roses?"</span>
  <span class="token constant">LISTEN</span> microphone

  <span class="token keyword">when</span> <span class="token string">"I like $color roses"</span>
    <span class="token keyword">or</span> <span class="token string">"$color ones"</span>
    <span class="token keyword">or</span> <span class="token string">"$color"</span>
    <span class="token keyword">with</span> color = <span class="token string">"red"</span>, <span class="token string">"blue"</span>

  say <span class="token string">"Hey, I like $color ones too."</span>
    <span class="token keyword">or</span> <span class="token string">"Nice! I like $color ones too."</span>
  <span class="token constant">END</span>

 <span class="token keyword">when</span> <span class="token constant">AMAZON</span>.RepeatIntent
  <span class="token string">-></span> askAboutRoses
</code></pre>

              </div>
            </div>


<div class="feature-callout" v-if="key === 1">
              <div class="language-coffeescript extra-class">
                <pre class="language-coffeescript"><code>apl
  <span class="token constant">document:</span> apl_doc.json
  <span class="token constant">data:</span> apl_data.json
  <span class="token constant">commands:</span> apl_commands.json

say <span class="token string">"turning page"</span>
apl
  <span class="token constant">commands:</span> turn_page.json

soundEffect page_chime.mp3
say <span class="token string">"page turned"</span>
</code></pre>
              </div>
            </div>

  <div class="feature-callout" v-if="key === 2">
              <div class="language-coffeescript extra-class">
                <pre class="language-coffeescript"><code><span class="token comment"># main.litexa</span>
<span class="token keyword">if</span> <span class="token string">@name</span>
  say <span class="token string">"Welcome back, @name."</span>
  <span class="token string">-></span> playGame
<span class="token keyword">else</span>
  <span class="token string">-></span> askName

askName
  say <span class="token string">"What's your name?"</span>

  <span class="token keyword">when</span> <span class="token string">"My name is $name"</span>
    <span class="token keyword">with</span> $name = <span class="token constant">AMAZON.US_FIRST_NAME</span>

    say <span class="token string">"Hi, {formatName($name)}"</span>
    <span class="token comment"># store the result permanently</span>
    <span class="token string">@name</span> = $name

<span class="token comment">// litexa/main.js</span>
<span class="token keyword">function</span> <span class="token constant">formatName</span>(name) {
  <span class="token keyword">return</span> <span class="token string">`the most honorable</span> ${name}<span class="token string">`</span>;
}
</span>
</code></pre>
              </div>
            </div>

          </div>
        </div>
      </div>



      <!--
      <div class="state-of-mind">
        <h2>State of Mind</h2>TODO: This will be replaced with Chris's interactive demo...
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 1187 706"
        >
          <g>
            <g>
              <rect style="fill:#292c32" width="1187" height="706"></rect>
            </g>
          </g>
        </svg>
      </div>
      -->
    </div>
    <div class="stripe">
      <Content class="home-aligned" :custom="false"/>
    </div>
    <div class="faqs" v-if="data.faqs && data.faqs.length">
      <div class="faq" v-for="(faq, index) in data.faqs" :key="index">
        <div class="header-wrapper">
          <h2>{{ faq.question }}</h2>
        </div>
        <p v-html="faq.answer"></p>
      </div>
    </div>
    <div class="footer" v-if="data.footer">{{ data.footer }}</div>

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

<script>
import NavLink from "./NavLink.vue";
import LitexaIntro from "./LitexaIntro.vue";

export default {
  components: { NavLink, LitexaIntro },

  computed: {
    data() {
      return this.$page.frontmatter;
    },

    actionLink() {
      return {
        link: this.data.actionLink,
        text: this.data.actionText
      };
    }
  }
};
</script>

<style lang="stylus">
@import './styles/config.styl';
@import './styles/clouds.styl';

.cloud-container {
  background-repeat: no-repeat;
  position: absolute;

  @media (max-width: $MQMobile) {
    display: none;
  }
}

.language-coffeescript {
  .intent {
    text-decoration: underline;
  }
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
  cloudScroll(1, 0);
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
  baloonBob(1, 0);
}

.cloud-twins ~ .cloud-twins {
  top: 1820px;
}

.cloud-righty {
  width: 808px;
  height: 540px;
  top: 330px;
  transition: all 4.3s ease;
  cloudScroll(0.7, 0.6);
}

.cloud-righty ~ .cloud-righty {
  top: 1930px;
  cloudScroll(0.4, 0.3);
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
  cloudScroll(0.9, 0.3);
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
  cloudScroll(0.5, 0.1);
}

.cloud-fluffy ~ .cloud-fluffy{
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

.home {
  padding: $navbarHeight 0;

  .home-aligned {
    max-width: 960px;
    margin: 0px auto;
  }

  .stripe {
    color: #fff;
    background-color: $accentColor;
    position: relative;
    z-index: 2;

    .home-aligned {
      h2 {
        padding: 20px 0px;
      }
    }
  }

  .state-of-mind {
    margin: 10px 0px 60px 0px;
  }

  .content, .state-of-mind {
    h2 {
      font-size: 2rem;
      text-align: center;
      font-weight: 500;
      border: none;
    }
  }

  .hero {
    text-align: center;
    margin-top: 5rem;
    position: relative;
    z-index: 2;

    img {
      max-height: 280px;
      display: block;
      margin: 3rem auto 1.5rem;
    }

    h1 {
      font-size: 3.5rem;
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
      font-weight: 300;
      color: #fff;
      background-color: $accentColor;
      padding: 0.4rem 2rem;
      border-radius: 8px;
      transition: background-color 0.1s ease;
      box-sizing: border-box;
      border-bottom: 1px solid darken($accentColor, 10%);

      &:hover {
        background-color: lighten($accentColor, 10%);
      }
    }
  }

  .minor-features {
    padding: 1.2rem 0;
    margin-top: 2.5rem;
    margin-bottom: 2.5rem;
    display: flex;
    flex-wrap: wrap;
    align-items: flex-start;
    align-content: stretch;
    justify-content: center;
  }

  .minor-feature {
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

  .faqs {
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

  .faq {
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

    .header-wrapper {
      position: relative;
      height: 3.5em;

      h2 {
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        font-size: 1.6rem;
        font-weight: 500;
        border: none;
        padding: 0;
        margin: 0;
        color: lighten($textColor, 10%);
      }
    }

    p {
      color: lighten($textColor, 25%);
    }
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
    }

    .arrow {
      color: $accentColor;
    }

    button {
      margin-right: 8px;
      background: $secondAccentColor !important;
      border: 0px;
      border-radius: 6px;
      color: #fff;
      cursor: pointer;
      transition: all 0.2s ease;
      box-shadow: 0px 0px 0px 0px $secondAccentColor;

      a {
        display: block;
        padding: 10px;
        color: #fff;
        padding-left: 20px;
        padding-right: 20px;
      }

      &:hover {
        box-shadow: 0px 9px 28px -9px $secondAccentColor;
      }
    }
  }

  .feature-content {
    max-width: 1300px;
    width: 100%;
    margin: 0px auto;
  }

  .features {
    // border-top 1px solid $borderColor
    // box-shadow: 0px -7px 20px -10px rgba(0, 0, 0, 0.1);
    padding: 0;
    margin-top: 2.5rem;
    // display flex
    // flex-wrap wrap
    // align-items: center;
  }

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

      div, pre, code {
        overflow: visible;
        padding: 0;
        margin: 0;
      }

      div.language-coffeescript {
        background: #fff;
        margin-top: 30px;
        border-radius: 0 0 6px 6px;

        pre {
          background: transparent;
          padding: 1.5em;
          font-size: 11.5pt;

          code {
            color: #333;

            .token.string {
              color: #090;
            }

            .token.keyword {
              color: #a09;
            }

            .token.constant {
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

    .features {
      flex-direction: column;
    }

    .feature {
      flex-direction: column;
      max-width: 100%;
      padding: 0 2.5rem;
    }

    .minor-feature {
      max-width: 100%;
      min-height: inherit;
      margin: 1em;
    }

    .faq {
      max-width: 100%;
      margin: 1em;
      height: auto;
      min-height: auto;

      .header-wrapper {
        height: auto;

        h2 {
          position: relative;
        }
      }
    }
  }
}

@media (max-width: $MQMobileNarrow) {
  .home {
    padding-left: 1.5rem;
    padding-right: 1.5rem;

    .hero {
      img {
        max-height: 210px;
        margin: 2rem auto 1.2rem;
      }

      h1 {
        font-size: 2rem;
      }

      h1, .description .action {
        margin: 1.2rem auto;
      }

      .description {
        font-size: 1.2rem;
        padding: 1em;
      }

      .action-button {
        font-size: 1rem;
        padding: 0.6rem 1.2rem;
      }
    }

    .features {
      padding: 0;
    }

    .feature {
      padding: 0;

      .feature-text {
        padding: 1em 0;
      }

      h2 {
        font-size: 1.25rem;
        padding: 0.5em;
      }
    }

    .faq {
      padding: 1em 0;
    }
  }
}
</style>
