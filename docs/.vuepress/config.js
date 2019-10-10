const path = require('path');
const execSync = require('child_process').execSync;

/*
 * Search for Vue Dependencies in Global Space
 * This allows us to get rid of "dangling" dependencies for doc generation and pushes that
 * responsibility onto doc authors.
 */
const globalNodeModulesPath = execSync('npm root -g', { encoding: 'utf-8' })
    .replace('\r\n', '') // Windows Line Endings
    .replace('\n', '');
const markdownGlobalDep = path.join(globalNodeModulesPath, 'markdown-it-vuepress-code-snippet-enhanced');

module.exports = {
  title: 'Litexa',
  description: 'A domain specific language for building Alexa Skills',
  head: [
    ['link', { rel: 'icon', href: `/icon.png` }],
    ['link', { rel: 'manifest', href: '/manifest.json' }],
    ['meta', { name: 'theme-color', content: '#00CAFF' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    //  ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }],
    //  ['link', { rel: 'apple-touch-icon', href: `/icons/apple-touch-icon-152x152.png` }],
    //  ['link', { rel: 'mask-icon', href: '/icons/safari-pinned-tab.svg', color: '#3eaf7c' }],
    //  ['meta', { name: 'msapplication-TileImage', content: '/icons/msapplication-icon-144x144.png' }],
    //  ['meta', { name: 'msapplication-TileColor', content: '#000000' }]
  ],
  markdown: {
    lineNumbers: false,
    config: md => {
        md.use(require(markdownGlobalDep))
    }
  },
  themeConfig: {
    sidebar: 'auto',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Get Started', link: '/get-started/' },
      { text: 'The Book', link: '/book/'},
      { text: 'Reference', link: '/reference/'},
      { text: 'GitHub', link: 'https://github.com/alexa-games/litexa' },
    ],
    sidebarDepth: 3,
    sidebar: [
      {
        title: 'Get Started',
        collapsable: false,
        children: [
          '/get-started/'
        ]
      },
      {
        title: 'The Book',
        collapsable: true,
        children: [
          '/book/',
          '/book/state-management',
          '/book/expressions',
          '/book/interop',
          '/book/presentation',
          '/book/screens',
          '/book/companion-app',
          '/book/monetization',
          '/book/gadgets-custom-interfaces',
          '/book/gadgets-echo-buttons',
          '/book/localization',
          '/book/project-structure',
          '/book/testing',
          '/book/deployment',
          '/book/extensions',
          '/book/backdoor',
          '/book/appendix-aws-permissions',
          '/book/appendix-default-aws-settings',
          '/book/appendix-editor-support',
          '/book/appendix-render-template',
          '/book/appendix-wav-conversion'
        ]
      },
      {
        title: 'Reference',
        collapsable: false,
        children: [
          '/reference/',
          '/reference/inlined-code-tests'
        ]
      }
    ]
  }
}
