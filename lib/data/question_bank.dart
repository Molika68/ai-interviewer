/// 内置面试题库。
///
/// 离线模式（无网络、无 API Key）下直接从此题库抽题，并用关键词命中率
/// 做规则评分，保证 App 在任何环境都能完整跑通一场面试。
library;

/// 题库条目：题目、涉及技术栈、评分关键词、参考答案要点。
class QuestionSeed {
  const QuestionSeed({
    required this.text,
    required this.techSkills,
    required this.keywords,
    required this.reference,
  });

  final String text;
  final List<String> techSkills;
  final List<String> keywords;
  final String reference;
}

const List<QuestionSeed> kQuestionBank = <QuestionSeed>[
  QuestionSeed(
    text: '请说说浏览器输入 URL 到页面渲染完成，中间发生了什么？',
    techSkills: <String>['浏览器', '网络'],
    keywords: <String>['DNS', 'TCP', 'TLS', 'HTTP', '解析', 'DOM', 'CSSOM', '渲染', '回流', '重绘'],
    reference: 'DNS 解析 → TCP 三次握手 → TLS 握手 → 发送 HTTP 请求 → 服务端响应 → '
        '浏览器解析 HTML 生成 DOM、解析 CSS 生成 CSSOM → 合成渲染树 → 布局（Layout）→ 绘制（Paint）→ 合成（Composite）上屏。'
        '补充点：强缓存/协商缓存、CDN、HTTP/2 多路复用、关键渲染路径优化。',
  ),
  QuestionSeed(
    text: 'Vue 的响应式原理是什么？Vue 2 和 Vue 3 的实现有什么区别？',
    techSkills: <String>['Vue'],
    keywords: <String>['Object.defineProperty', 'Proxy', '依赖收集', 'Watcher', '发布订阅', 'Reflect'],
    reference: 'Vue 2 用 Object.defineProperty 劫持属性的 getter/setter，需要递归遍历对象、'
        '且无法检测属性新增删除和数组下标变化（用重写数组方法兜底）；Vue 3 改用 Proxy 代理整个对象，'
        '惰性递归、支持新增删除属性和数组索引，配合 Reflect 和 effect 做依赖收集与派发更新。',
  ),
  QuestionSeed(
    text: 'React 的 Fiber 架构解决了什么问题？',
    techSkills: <String>['React'],
    keywords: <String>['Fiber', '可中断', '时间切片', '链表', 'reconciler', '优先级', 'Scheduler'],
    reference: '老版 Stack Reconciler 递归遍历组件树不可中断，长任务会阻塞主线程导致掉帧。'
        'Fiber 把渲染拆成可中断的工作单元，通过链表结构串联，配合 Scheduler 做时间切片与优先级调度，'
        '实现可恢复、可中止、可复用的增量渲染。',
  ),
  QuestionSeed(
    text: '说说事件循环（Event Loop）中宏任务与微任务的执行顺序。',
    techSkills: <String>['JavaScript'],
    keywords: <String>['宏任务', '微任务', 'Promise', 'queueMicrotask', 'setTimeout', '调用栈'],
    reference: '同步代码执行完毕后，先清空微任务队列（Promise.then、MutationObserver、queueMicrotask），'
        '再取一个宏任务（setTimeout、I/O、UI 渲染）执行，然后再次清空微任务，如此循环。'
        '注意 await 后面的代码相当于微任务。',
  ),
  QuestionSeed(
    text: '什么是闭包？闭包会导致什么问题，如何避免内存泄漏？',
    techSkills: <String>['JavaScript'],
    keywords: <String>['作用域链', '引用', '垃圾回收', '内存泄漏', '解除引用', 'IIFE'],
    reference: '闭包是函数与其词法作用域的组合，能访问外部函数变量。'
        '因为闭包持有外部变量引用，可能导致变量无法被回收，常见于定时器、事件监听、DOM 引用。'
        '避免方式：及时 clearInterval、removeEventListener、把引用置为 null。',
  ),
  QuestionSeed(
    text: '前端性能优化你做过哪些？列举具体手段和量化结果。',
    techSkills: <String>['性能'],
    keywords: <String>['首屏', '懒加载', '缓存', 'CDN', '压缩', '代码分割', '预加载', 'LCP', 'FCP'],
    reference: '手段：路由级代码分割、图片懒加载与 WebP、资源压缩与 Tree Shaking、CDN 加速、'
        'HTTP 缓存策略、骨架屏、虚拟列表、减少重排、预连接与资源提示。'
        '量化：关注 LCP / FID / CLS 等 Core Web Vitals，说明优化前后的具体数值。',
  ),
  QuestionSeed(
    text: '讲讲 HTTP 缓存：强缓存和协商缓存的区别与命中流程。',
    techSkills: <String>['网络'],
    keywords: <String>['Cache-Control', 'max-age', 'Expires', 'ETag', 'Last-Modified', '304'],
    reference: '强缓存看 Cache-Control（max-age、no-cache、no-store）和 Expires，命中直接不发请求，返回 200 (from disk/memory cache)；'
        '未命中则进入协商缓存，请求带 If-None-Match (ETag) 或 If-Modified-Since，服务端判断未变更返回 304，'
        '浏览器沿用本地副本。',
  ),
  QuestionSeed(
    text: 'HTTPS 的握手过程是怎样的？中间人攻击如何防范？',
    techSkills: <String>['网络', '安全'],
    keywords: <String>['TLS', '证书', 'CA', '公钥', '私钥', '对称加密', '非对称加密', '校验'],
    reference: '客户端发起 ClientHello → 服务端返回证书 → 客户端校验证书链与域名 → '
        '用证书公钥加密预主密钥 → 双方派生对称会话密钥 → 后续走对称加密。'
        '防范中间人：证书链校验、证书固定（pinning）、HSTS、不忽略证书错误。',
  ),
  QuestionSeed(
    text: '常见的前端鉴权方案有哪些？JWT 和 Session 各自的优缺点？',
    techSkills: <String>['安全', '后端'],
    keywords: <String>['JWT', 'Session', 'Cookie', 'HttpOnly', 'Refresh Token', '无状态'],
    reference: 'Session + Cookie：服务端存状态，天然可控可注销，但需要存储与共享（Redis），有 CSRF 风险；'
        'JWT：服务端无状态、易横向扩展，但令牌一旦签发难以即时失效，需要配合短有效期 + Refresh Token，'
        '存放避免 localStorage（XSS 风险），优先 HttpOnly Cookie。',
  ),
  QuestionSeed(
    text: '说说 XSS 和 CSRF 的原理与防御方式。',
    techSkills: <String>['安全'],
    keywords: <String>['XSS', 'CSRF', '转义', 'CSP', 'Token', 'SameSite', 'HttpOnly'],
    reference: 'XSS：注入恶意脚本，分存储型/反射型/DOM 型；防御：输入输出转义、CSP、避免 innerHTML、HttpOnly Cookie。'
        'CSRF：诱导用户在已登录状态下发起跨站请求；防御：CSRF Token、SameSite=Lax/Strict Cookie、校验 Origin/Referer。',
  ),
  QuestionSeed(
    text: '前端工程化里，Webpack 和 Vite 的核心差异是什么？',
    techSkills: <String>['工程化'],
    keywords: <String>['打包', 'ESM', '预构建', 'HMR', '依赖', '冷启动', 'esbuild'],
    reference: 'Webpack 启动时先打包整个依赖图再提供服务，冷启动随项目变大变慢；'
        'Vite 利用浏览器原生 ESM，按需编译，依赖用 esbuild 预构建，HMR 只失效单模块，'
        '冷启动和更新速度都快很多，生产构建仍用 Rollup。',
  ),
  QuestionSeed(
    text: '请解释 Tree Shaking 的原理，以及什么情况下会失效。',
    techSkills: <String>['工程化'],
    keywords: <String>['ESM', '静态分析', '副作用', 'sideEffects', 'dead code', 'CommonJS'],
    reference: 'Tree Shaking 依赖 ESM 的静态结构做可达性分析，删除未被引用的导出。'
        '失效场景：使用 CommonJS、存在副作用无法判定（需在 package.json 声明 sideEffects）、'
        '动态导入或运行时的属性访问、被标记为 pure 之外的函数调用。',
  ),
  QuestionSeed(
    text: 'Vue 组件之间通信有哪些方式？分别适用什么场景？',
    techSkills: <String>['Vue'],
    keywords: <String>['props', 'emit', 'provide', 'inject', 'Pinia', 'Vuex', '事件总线', 'ref'],
    reference: '父子：props / emit / ref / v-model；跨层：provide/inject；'
        '任意组件：Pinia（或 Vuex）全局状态、事件总线（谨慎用）；路由参数、URL query 也算。'
        '复杂共享状态优先 Pinia，避免滥用事件总线导致数据流难追踪。',
  ),
  QuestionSeed(
    text: 'React 中 useMemo 和 useCallback 的作用与使用场景？',
    techSkills: <String>['React'],
    keywords: <String>['缓存', '引用', '依赖', '重渲染', 'memo', '性能'],
    reference: 'useMemo 缓存计算结果，useCallback 缓存函数引用，都基于依赖数组。'
        '适用：计算开销大、作为 memo 子组件 props、作为 useEffect 依赖。'
        '不要无脑加，缓存本身也有成本，过度使用反而增加内存与复杂度。',
  ),
  QuestionSeed(
    text: '虚拟列表（Virtual List）的实现思路是什么？',
    techSkills: <String>['性能', 'JavaScript'],
    keywords: <String>['可视区域', '滚动', '缓冲区', '高度', '复用', 'transform', '占位'],
    reference: '只渲染可视区域 + 上下缓冲区的元素，用容器总高度撑起滚动条，'
        '通过 translateY 偏移渲染窗口，滚动时按 scrollTop 计算起止索引并回收 DOM。'
        '难点：不定高场景需要测量与缓存高度。',
  ),
  QuestionSeed(
    text: '说说 TypeScript 中泛型的作用，举一个你实际用过的例子。',
    techSkills: <String>['TypeScript'],
    keywords: <String>['泛型', '复用', '约束', 'extends', '类型推导', '接口'],
    reference: '泛型让类型作为参数传递，在保证类型安全的同时复用逻辑。'
        '例如封装请求函数：async function request<T>(url: string): Promise<ApiResponse<T>>，'
        '调用时 request<User[]>(\'/users\') 直接得到强类型结果；也可用 extends 做约束，keyof 做键约束。',
  ),
  QuestionSeed(
    text: 'Node.js 中如何避免阻塞事件循环？遇到过哪些坑？',
    techSkills: <String>['Node.js'],
    keywords: <String>['异步', '事件循环', 'worker', '线程池', '同步', 'CPU密集', 'stream'],
    reference: '避免同步 API（fs.readFileSync、crypto 同步）、大 JSON 解析、复杂正则回溯；'
        'CPU 密集任务交给 worker_threads 或拆分为子进程/队列；大文件用 stream；'
        'CPU 密集拆分可用 setImmediate 让出事件循环。',
  ),
  QuestionSeed(
    text: 'NestJS 的依赖注入是怎么工作的？它的优势是什么？',
    techSkills: <String>['NestJS'],
    keywords: <String>['依赖注入', '装饰器', 'Module', 'Provider', '生命周期', '反射'],
    reference: 'Nest 基于装饰器与 reflect-metadata 收集类型元数据，IoC 容器按模块注册 Provider 并解析依赖，'
        '自动实例化并注入构造函数参数。优势：解耦、易测试（可替换 mock）、模块化组织、生命周期钩子清晰。',
  ),
  QuestionSeed(
    text: '数据库索引的作用是什么？什么时候索引会失效？',
    techSkills: <String>['数据库'],
    keywords: <String>['索引', 'B+树', '最左前缀', '回表', '覆盖索引', '函数', '隐式转换'],
    reference: '索引加速查询、减少扫描行数，InnoDB 用 B+ 树。'
        '失效场景：不满足最左前缀、在列上做函数运算或隐式类型转换、使用 != / NOT IN、'
        '以 % 开头的 like、优化器判断全表更快、OR 条件未全部命中索引。',
  ),
  QuestionSeed(
    text: '什么是跨域？CORS 预检请求（OPTIONS）是怎么触发的？',
    techSkills: <String>['网络'],
    keywords: <String>['同源策略', 'CORS', 'OPTIONS', '预检', '简单请求', 'Access-Control'],
    reference: '同源策略限制协议/域名/端口不同的资源访问。CORS 通过响应头授权。'
        '非简单请求（自定义头、Content-Type 为 application/json、PUT/DELETE 等方法）会先发 OPTIONS 预检，'
        '服务端需返回 Access-Control-Allow-Origin/Methods/Headers，并可用 Max-Age 缓存预检结果。',
  ),
  QuestionSeed(
    text: '如何排查线上页面白屏或报错问题？说说你的排查流程。',
    techSkills: <String>['工程化', '性能'],
    keywords: <String>['监控', 'source map', '日志', 'sentry', '复现', '灰度', '回滚', '埋点'],
    reference: '流程：确认影响范围与版本 → 查监控/错误上报（Sentry）与 source map 定位堆栈 → '
        '结合灰度版本与发布记录定位变更 → 本地/预发复现 → 修复并灰度验证 → 必要时回滚。'
        '长期手段：前端埋点、错误边界、性能监控、告警。',
  ),
  QuestionSeed(
    text: '说说你对前端状态管理的理解，什么情况下需要引入？',
    techSkills: <String>['状态管理'],
    keywords: <String>['共享状态', '单向数据流', 'Pinia', 'Redux', 'Riverpod', '局部状态', '提升'],
    reference: '状态管理的本质是管理跨组件共享数据与变更来源。'
        '优先用局部状态 + 状态提升；当数据被多层级、多路由共享，或需要缓存/持久化/时间旅行调试时，'
        '再引入 Pinia/Redux/Riverpod 等方案，并明确单一数据流与不可变更新。',
  ),
  QuestionSeed(
    text: '讲讲 Webpack 的构建流程，以及你如何做构建提速。',
    techSkills: <String>['工程化'],
    keywords: <String>['loader', 'plugin', 'AST', 'chunk', '缓存', 'thread', '分包', '持久化'],
    reference: '流程：初始化参数 → 编译（loader 转译、AST 分析依赖）→ 生成 chunk → 输出产物。'
        '提速：持久化缓存（cache filesystem）、thread-loader / parallel、缩小 loader 作用范围、'
        'externals + CDN、合理分包与按需加载、升级到 Vite/Rspack。',
  ),
  QuestionSeed(
    text: '什么是重排（Reflow）和重绘（Repaint）？如何减少？',
    techSkills: <String>['浏览器', '性能'],
    keywords: <String>['重排', '重绘', '布局', 'transform', '合成层', '批量', '读写分离'],
    reference: '重排是重新计算布局几何，重绘是重新绘制像素；重排必然触发重绘。'
        '减少：批量修改 DOM（DocumentFragment）、避免逐条读写布局属性（先读后写）、'
        '用 transform/opacity 走合成层、脱离文档流做动画、避免使用 table 布局。',
  ),
  QuestionSeed(
    text: '请介绍一下你做过的项目中，技术选型是怎么决策的？',
    techSkills: <String>['综合'],
    keywords: <String>['业务', '团队', '成本', '生态', '维护', '调研', '风险', '对比'],
    reference: '从业务场景与约束出发：功能诉求、团队技术栈与学习成本、生态成熟度与社区活跃度、'
        '长期维护与招聘成本、性能与包体积、迁移风险。'
        '给出对比结论与兜底方案，并用 POC 验证关键假设。',
  ),
  QuestionSeed(
    text: '前端如何做错误监控与日志上报？',
    techSkills: <String>['工程化'],
    keywords: <String>['try', 'onerror', 'unhandledrejection', 'sentry', '上报', '采样', '埋点'],
    reference: '捕获：window.onerror、unhandledrejection、框架错误边界、请求拦截器统一处理；'
        '上报：图片打点或 sendBeacon，做采样、节流与去重；'
        '定位：source map 上传、关联 release 版本与用户行为轨迹（面包屑）。',
  ),
  QuestionSeed(
    text: '讲讲 Promise 的实现原理，以及如何手写 Promise.all？',
    techSkills: <String>['JavaScript'],
    keywords: <String>['状态', 'then', '微任务', 'resolve', 'reject', '计数', '数组'],
    reference: 'Promise 有三种状态（pending/fulfilled/rejected），状态不可逆；then 返回新 Promise 支持链式调用，'
        '回调在微任务中执行。Promise.all：返回新 Promise，遍历数组用计数判断全部完成，任一 reject 则整体 reject，'
        '结果按输入顺序保存。',
  ),
  QuestionSeed(
    text: '说说 SSR 和 CSR 的区别，以及 SSR 的适用场景与代价。',
    techSkills: <String>['Next.js', '工程化'],
    keywords: <String>['SSR', 'CSR', '首屏', 'SEO', '水合', 'hydration', '服务端压力'],
    reference: 'CSR 首屏需等 JS 下载执行，白屏时间长、SEO 差；SSR 服务端直出 HTML，首屏快、利于 SEO。'
        '代价：服务端渲染压力、水合不一致风险、部署复杂度与缓存策略、需要 Node 运行时。'
        '适用于内容型、首屏与 SEO 敏感的页面。',
  ),
  QuestionSeed(
    text: '如何设计一个高可用的组件？你会考虑哪些方面？',
    techSkills: <String>['组件设计'],
    keywords: <String>['props', '受控', '插槽', '可访问性', '文档', '测试', '边界', '复用'],
    reference: '明确单一职责与 API 边界（props/事件/插槽）、受控与非受控兼容、'
        '处理边界与空态、可访问性与键盘操作、样式可覆盖、'
        '配套文档与单测、版本兼容与废弃策略。',
  ),
  QuestionSeed(
    text: '讲讲你对 Web 无障碍（A11y）的理解，做过哪些实践？',
    techSkills: <String>['综合'],
    keywords: <String>['语义化', 'aria', '键盘', '对比度', '焦点', 'label', '屏幕阅读器'],
    reference: '使用语义化标签（button/nav/main）、为图标按钮加 aria-label、'
        '保证键盘可达与焦点可见、颜色对比度达标、表单关联 label、'
        '动态内容用 aria-live 播报，并用屏幕阅读器实测。',
  ),
  QuestionSeed(
    text: '当需求不明确或排期很紧时，你如何推进工作？',
    techSkills: <String>['综合'],
    keywords: <String>['沟通', '拆解', '优先级', 'MVP', '风险', '同步', '确认'],
    reference: '先与需求方对齐目标与验收标准，拆解为可交付的最小闭环（MVP），'
        '明确优先级与风险点并提前同步；过程中保持短周期反馈，'
        '必要时用数据或原型替代争论，记录决策原因。',
  ),
];
