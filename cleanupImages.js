const fs = require('fs-extra')
const path = require('path')

/**
 * 清理旧图片文件
 * @param {string} imagesDir - 图片目录路径
 * @param {number} maxAgeHours - 文件最大保存时长（小时），默认24小时
 * @returns {Promise<{deleted: number, errors: number}>}
 */
async function cleanupOldImages(imagesDir, maxAgeHours = 24) {
  const stats = {
    deleted: 0,
    errors: 0,
    scanned: 0
  }

  try {
    // 确保目录存在
    if (!await fs.pathExists(imagesDir)) {
      console.log(`[清理任务] 图片目录不存在: ${imagesDir}`)
      return stats
    }

    const now = Date.now()
    const maxAge = maxAgeHours * 60 * 60 * 1000 // 转换为毫秒
    
    console.log(`[清理任务] 开始清理图片，保留时长: ${maxAgeHours}小时`)

    // 读取目录中的所有文件
    const files = await fs.readdir(imagesDir)
    stats.scanned = files.length

    for (const file of files) {
      const filePath = path.join(imagesDir, file)
      
      try {
        const stat = await fs.stat(filePath)
        
        // 只处理文件，跳过目录
        if (!stat.isFile()) {
          continue
        }

        // 只处理图片文件
        const ext = path.extname(file).toLowerCase()
        if (!['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg'].includes(ext)) {
          continue
        }

        // 计算文件年龄
        const fileAge = now - stat.mtime.getTime()
        
        if (fileAge > maxAge) {
          await fs.remove(filePath)
          stats.deleted++
          console.log(`[清理任务] 已删除: ${file} (创建于 ${new Date(stat.mtime).toLocaleString('zh-CN')})`)
        }
      } catch (err) {
        stats.errors++
        console.error(`[清理任务] 处理文件失败 ${file}:`, err.message)
      }
    }

    console.log(`[清理任务] 完成 - 扫描: ${stats.scanned}, 删除: ${stats.deleted}, 错误: ${stats.errors}`)
  } catch (error) {
    console.error('[清理任务] 执行失败:', error)
    stats.errors++
  }

  return stats
}

/**
 * 获取目录统计信息
 * @param {string} imagesDir - 图片目录路径
 * @returns {Promise<{count: number, totalSize: number}>}
 */
async function getDirectoryStats(imagesDir) {
  const stats = {
    count: 0,
    totalSize: 0
  }

  try {
    if (!await fs.pathExists(imagesDir)) {
      return stats
    }

    const files = await fs.readdir(imagesDir)
    
    for (const file of files) {
      const filePath = path.join(imagesDir, file)
      try {
        const stat = await fs.stat(filePath)
        if (stat.isFile()) {
          stats.count++
          stats.totalSize += stat.size
        }
      } catch (err) {
        // 忽略单个文件错误
      }
    }
  } catch (error) {
    console.error('[统计任务] 执行失败:', error)
  }

  return stats
}

module.exports = {
  cleanupOldImages,
  getDirectoryStats
}

