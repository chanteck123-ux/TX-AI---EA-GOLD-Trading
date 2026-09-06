const fs = require('fs');
const path = require('path');
const {pathToFileURL} = require('url');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

(async () => {
  const target = path.resolve(process.argv[2]);
  const out = path.resolve(process.argv[3]);
  fs.mkdirSync(out, {recursive:true});
  const browser = await chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});
  const results = [];
  try {
    for (const viewport of [{width:1440,height:1000},{width:390,height:844}]) {
      const page = await browser.newPage({viewport});
      const errors=[];
      page.on('pageerror', error => errors.push(error.message));
      await page.goto(pathToFileURL(target).href);
      await page.locator('h1').waitFor();
      await page.screenshot({path:path.join(out,`top-${viewport.width}.png`)});
      await page.screenshot({path:path.join(out,`report-${viewport.width}.png`),fullPage:true});
      const state = await page.evaluate(() => ({
        documentWidth:document.documentElement.scrollWidth, viewport:innerWidth,
        images:[...document.images].map(i => ({src:i.getAttribute('src'),loaded:i.complete&&i.naturalWidth>0})),
        tables:[...document.querySelectorAll('table')].map(t => ({
          headers:t.querySelectorAll('thead th').length,
          body:[...t.querySelectorAll('tbody tr')].map(r=>r.cells.length)
        }))
      }));
      if (state.documentWidth>state.viewport || state.images.some(i=>!i.loaded) || errors.length ||
          state.tables.some(t=>t.body.some(n=>n!==t.headers))) throw Error(JSON.stringify({viewport,state,errors}));
      await page.locator('details').first().evaluate(e=>e.open=true);
      await page.locator('details').first().scrollIntoViewIfNeeded();
      await page.screenshot({path:path.join(out,`detail-${viewport.width}.png`)});
      results.push({viewport,state,errors,status:'PASS'});
      await page.close();
    }
  } finally {await browser.close();}
  fs.writeFileSync(path.join(out,'VISUAL_QA.json'),JSON.stringify(results,null,2));
  console.log(JSON.stringify(results.map(r=>({viewport:r.viewport,status:r.status,images:r.state.images.length}))));
})().catch(error=>{console.error(error);process.exit(1);});
