

const sidebar = [
  {
    title: 'Get Started',
    collapsable: true,
    children: [
      '/get-started/',
      '/get-started/project-generation-and-structure',
      '/get-started/litexa-code',
      '/get-started/running',
      '/get-started/deploying',
      '/get-started/learn-more'
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


const nav = [
  { text: 'Home', link: '/' },
  { text: 'Get Started', link: '/get-started/' },
  { text: 'The Book', link: '/book/'},
  { text: 'Reference', link: '/reference/'}
]


module.exports = {
  title: 'litexa',
  description: 'A domain specific language for building Alexa skills',
  themeConfig: {
    algolia: {
      apiKey: '33046bfd9da3c88f198ad313db688f1f',
      indexName: 'litexa'
    },
    nav, sidebar,
    sidebarDepth: 3,
    repo: 'alexa-games/litexa',
    docsDir: 'docs',
    editLinks: true,
    editLinkText: 'Help us improve this page on GitHub!',
    logo: "/logo.png",
    search: true
  },
  head: [
    ['link', { rel: 'icon', href: `/icon.png` }],
    ['link', { rel: 'manifest', href: '/manifest.json' }],
    ['meta', { name: 'theme-color', content: '#00CAFF' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: "viewport", content:"width=device-width, initial-scale=1" }]
  ]
}