const express = require('express')
const { render } = require('@antv/gpt-vis-ssr')
const fs = require('fs-extra')
const path = require('path')
const { v4: uuidv4 } = require('uuid')
const cron = require('node-cron')
const { cleanupOldImages, getDirectoryStats } = require('./cleanupImages')

const app = express()
const port = process.env.PORT || 8084
const publicDir = path.join(__dirname, 'public')
const imagesDir = path.join(publicDir, 'images')

// 从环境变量读取配置，可以在 docker-compose.yml 中配置
const CLEANUP_ENABLED = process.env.CLEANUP_ENABLED !== 'false' // 默认启用
const CLEANUP_SCHEDULE = process.env.CLEANUP_SCHEDULE || '0 */6 * * *' // 默认每6小时执行一次
const MAX_IMAGE_AGE_HOURS = parseInt(process.env.MAX_IMAGE_AGE_HOURS || '24', 10) // 默认保留24小时

// 确保目录存在
fs.ensureDirSync(imagesDir)
console.error("================")

app.use(express.json())
app.use('/images', express.static(imagesDir))

app.post('/render', async (req, res) => {
  try {
    var options = req.body
	  console.log("=====", options)

    // 验证必要的参数
    //if (!options || !options.type || !options.data) {
    //  return res.status(400).json({
    //   success: false,
    //    errorMessage: '缺少必要的参数: type 或 data'
    //  })
    //}
	  console.log("========xuanran")
	  if (options.input != undefined){
		options = options.input
	  }

    // 渲染图表
    const vis = await render(options)
    const buffer = await vis.toBuffer()
	  console.log("=====yixuanran")

    // 生成唯一文件名并保存图片
    const filename = `${uuidv4()}.png`
    const filePath = path.join(imagesDir, filename)
    await fs.writeFile(filePath, buffer)
	  console.log("====baocuntupian====")

    // 构建图片URL
    const host = req.get('host')
    const protocol = req.protocol
    const imageUrl = `${protocol}://${host}/images/${filename}`

    res.json({
      success: true,
      resultObj: imageUrl
    })
  } catch (error) {
    console.error('渲染图表时出错:', error)
    res.status(500).json({
      success: false,
      errorMessage: `渲染图表失败: ${error.message}`
    })
  }
})

// 启动定时清理任务
if (CLEANUP_ENABLED) {
  console.log(`[定时任务] 图片清理已启用`)
  console.log(`[定时任务] Cron 表达式: ${CLEANUP_SCHEDULE}`)
  console.log(`[定时任务] 保留时长: ${MAX_IMAGE_AGE_HOURS}小时`)
  
  cron.schedule(CLEANUP_SCHEDULE, async () => {
    console.log('[定时任务] 开始执行图片清理...')
    const beforeStats = await getDirectoryStats(imagesDir)
    console.log(`[定时任务] 清理前: ${beforeStats.count}个文件, 总大小: ${(beforeStats.totalSize / 1024 / 1024).toFixed(2)}MB`)
    
    await cleanupOldImages(imagesDir, MAX_IMAGE_AGE_HOURS)
    
    const afterStats = await getDirectoryStats(imagesDir)
    console.log(`[定时任务] 清理后: ${afterStats.count}个文件, 总大小: ${(afterStats.totalSize / 1024 / 1024).toFixed(2)}MB`)
  })

  // 启动时执行一次清理
  setTimeout(async () => {
    console.log('[启动任务] 执行首次图片清理...')
    await cleanupOldImages(imagesDir, MAX_IMAGE_AGE_HOURS)
  }, 5000) // 延迟5秒执行，确保服务已完全启动
} else {
  console.log('[定时任务] 图片清理已禁用')
}

// 添加手动清理接口（可选）
app.post('/cleanup', async (req, res) => {
  try {
    const maxAge = req.body.maxAgeHours || MAX_IMAGE_AGE_HOURS
    const result = await cleanupOldImages(imagesDir, maxAge)
    const stats = await getDirectoryStats(imagesDir)
    
    res.json({
      success: true,
      result: {
        ...result,
        remaining: stats
      }
    })
  } catch (error) {
    console.error('手动清理失败:', error)
    res.status(500).json({
      success: false,
      errorMessage: `清理失败: ${error.message}`
    })
  }
})

// 添加统计接口（可选）
app.get('/stats', async (req, res) => {
  try {
    const stats = await getDirectoryStats(imagesDir)
    res.json({
      success: true,
      stats: {
        count: stats.count,
        totalSizeMB: (stats.totalSize / 1024 / 1024).toFixed(2)
      }
    })
  } catch (error) {
    console.error('获取统计失败:', error)
    res.status(500).json({
      success: false,
      errorMessage: `获取统计失败: ${error.message}`
    })
  }
})

app.listen(port, () => {
	console.log("==========port=")
  console.log(`GPT-Vis-SSR 服务运行在 http://localhost:${port}`)
})
