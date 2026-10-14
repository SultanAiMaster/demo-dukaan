// Demo Dukaan backend: Cloudflare Pages advanced-mode worker + one KV namespace bound as DB.
// Demo data resets itself once per IST day. Public demo, so inputs are length-capped.
const SEED = [
  ["atta","Whole Wheat Atta 5kg","Grocery",245,"Stone-ground whole wheat flour for soft rotis.","atta"],
  ["rice","Basmati Rice 5kg","Grocery",520,"Long grain aged basmati, loose and fluffy when cooked.","rice"],
  ["tea","Assam Tea 500g","Grocery",210,"Strong everyday loose-leaf Assam tea.","tea"],
  ["ghee","Desi Ghee 500ml","Grocery",385,"Slow-cooked desi ghee in a glass jar.","ghee"],
  ["biscuit","Butter Biscuits 400g","Grocery",90,"Crisp butter biscuits for tea time.","biscuit"],
  ["soap","Handmade Soap (pack of 3)","Grocery",150,"Plain handmade bath soaps.","soap"],
  ["oil","Mustard Oil 1L","Grocery",190,"Cold pressed mustard oil for cooking.","oil"],
  ["spices","Masala Combo","Grocery",175,"Red chilli, turmeric and cumin powder set.","spices"],
  ["tshirt","Cotton T-Shirt","Fashion",399,"Soft round-neck cotton tee, teal.","tshirt"],
  ["kurta","Men's Cotton Kurta","Fashion",799,"Off-white cotton kurta, regular fit.","kurta"],
  ["saree","Cotton Saree","Fashion",1299,"Maroon cotton saree with golden border.","saree"],
  ["jeans","Blue Denim Jeans","Fashion",999,"Straight fit denim jeans.","jeans"],
  ["dupatta","Printed Dupatta","Fashion",349,"Mustard printed cotton dupatta.","dupatta"],
  ["tote","Canvas Tote Bag","Fashion",299,"Beige canvas tote for daily use.","tote"],
  ["sneakers","Canvas Sneakers","Fashion",899,"White canvas sneakers.","sneakers"],
].map(([id,name,category,price,description,image],i)=>({id,name,category,price,description,image,created:i}));

const ADMIN_TOKEN = "demo-admin-token";
const json = (o, s=200) => new Response(JSON.stringify(o), {status:s, headers:{"content-type":"application/json","cache-control":"no-store"}});
const istDay = () => new Date(Date.now()+19800000).toISOString().slice(0,10);
const clip = (v,n) => String(v ?? "").slice(0,n);

async function load(env){
  const day = istDay();
  if ((await env.DB.get("day")) !== day) {
    await env.DB.put("day", day);
    await env.DB.put("products", JSON.stringify(SEED));
    await env.DB.put("orders", "[]");
  }
  return {
    products: JSON.parse((await env.DB.get("products")) || "[]"),
    orders: JSON.parse((await env.DB.get("orders")) || "[]"),
  };
}
const isAdmin = r => r.headers.get("x-admin-token") === ADMIN_TOKEN;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const p = url.pathname;
    if (!p.startsWith("/api/")) return env.ASSETS.fetch(request);
    const m = request.method;
    try {
      if (p === "/api/login" && m === "POST") {
        const b = await request.json();
        return b.user === "demo" && b.pass === "demo123" ? json({token: ADMIN_TOKEN}) : json({error:"Wrong login"},401);
      }
      if (p === "/api/demo-request" && m === "POST") {
        const b = await request.json();
        const row = {name:clip(b.name,80), shop:clip(b.shop,80), phone:clip(b.phone,20), at:new Date().toISOString()};
        if (!row.name || !row.phone) return json({error:"Name and phone needed"},400);
        let sheet = false;
        if (env.SHEET_WEBHOOK) {
          try { const r = await fetch(env.SHEET_WEBHOOK,{method:"POST",headers:{"content-type":"text/plain"},body:JSON.stringify({...row,phone:"'"+row.phone}),redirect:"follow"}); sheet = r.ok; } catch(e){}
        }
        const list = JSON.parse((await env.DB.get("demo_requests")) || "[]"); list.push({...row, sheet});
        await env.DB.put("demo_requests", JSON.stringify(list.slice(-500)));
        return json({ok:true});
      }
      const {products, orders} = await load(env);
      if (p === "/api/products" && m === "GET") return json(products);
      if (p === "/api/orders" && m === "POST") {
        const b = await request.json();
        const items = (Array.isArray(b.items)?b.items:[]).slice(0,30).map(i=>({name:clip(i.name,80),price:Number(i.price)||0,qty:Math.max(1,Math.min(99,Number(i.qty)||1))}));
        if (!items.length || !clip(b.name,60) || !clip(b.phone,20)) return json({error:"Missing details"},400);
        const o = {id:"O"+String(Date.now()).slice(-6), name:clip(b.name,60), phone:clip(b.phone,20), items, total:items.reduce((s,i)=>s+i.price*i.qty,0), status:"New", at:new Date().toISOString()};
        orders.unshift(o);
        await env.DB.put("orders", JSON.stringify(orders.slice(0,200)));
        return json(o);
      }
      if (!isAdmin(request)) return json({error:"Admin login needed"},401);
      if (p === "/api/orders" && m === "GET") return json(orders);
      let mt = p.match(/^\/api\/orders\/([^/]+)\/status$/);
      if (mt && m === "POST") {
        const b = await request.json(); const o = orders.find(x=>x.id===mt[1]);
        if (!o) return json({error:"Not found"},404);
        o.status = b.status === "Done" ? "Done" : "New";
        await env.DB.put("orders", JSON.stringify(orders)); return json(o);
      }
      if (p === "/api/products" && m === "POST") {
        if (products.length >= 60) return json({error:"Demo limit reached"},400);
        const b = await request.json();
        const pr = {id:"p"+Date.now(), name:clip(b.name,60), category:clip(b.category,30)||"Grocery", price:Math.max(0,Number(b.price)||0), description:clip(b.description,300), image:clip(b.image,300)||"tote", created:Date.now()};
        if (!pr.name) return json({error:"Name needed"},400);
        products.push(pr); await env.DB.put("products", JSON.stringify(products)); return json(pr);
      }
      mt = p.match(/^\/api\/products\/([^/]+)$/);
      if (mt && m === "PUT") {
        const b = await request.json(); const pr = products.find(x=>x.id===mt[1]);
        if (!pr) return json({error:"Not found"},404);
        Object.assign(pr,{name:clip(b.name,60)||pr.name, category:clip(b.category,30)||pr.category, price:Math.max(0,Number(b.price)||0), description:clip(b.description,300), image:clip(b.image,300)||pr.image});
        await env.DB.put("products", JSON.stringify(products)); return json(pr);
      }
      if (mt && m === "DELETE") {
        await env.DB.put("products", JSON.stringify(products.filter(x=>x.id!==mt[1]))); return json({ok:true});
      }
      return json({error:"Not found"},404);
    } catch (e) { return json({error:"Bad request"},400); }
  }
};
