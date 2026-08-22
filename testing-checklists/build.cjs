const fs=require("fs");
function build({data, out, key, title, brand, h1, lede, report}){
  let head=fs.readFileSync("_shell_head.txt","utf8");
  const tail=fs.readFileSync("_shell_tail.txt","utf8");
  const d=fs.readFileSync(data,"utf8");
  head=head.replace("<title>Aajoo Host Readiness</title>","<title>"+title+"</title>")
           .replace("aajoo <span>host readiness</span>","aajoo <span>"+brand+"</span>")
           .replace("<h1>Host system readiness</h1>","<h1>"+h1+"</h1>")
           .replace(/Every host-facing feature on Aajoo, in the order a real host meets them — from creating an\s+account to being paid\./, lede);
  const t=tail.replace('const KEY="aajoo-host-qa-v1"','const KEY="'+key+'"')
              .replace("# Aajoo host testing — findings", report);
  fs.writeFileSync(out, head+d+t);
  const items=(d.match(/^\s{4}\[/gm)||[]).length;
  const secs=(d.match(/^\s{2}\{ t:/gm)||[]).length;
  console.log(out+"  —  "+secs+" phases, "+items+" checks, "+(head+d+t).length+" bytes");
}
build({
  data:"_renter_data.js", out:"guest-checklist.html", key:"aajoo-guest-qa-v1",
  title:"Aajoo Guest Readiness", brand:"guest readiness", h1:"Guest system readiness",
  lede:"Every guest-facing feature on Aajoo, in the order a real guest meets them — from landing on the site to reviewing the stay afterwards.",
  report:"# Aajoo guest testing — findings"
});
build({
  data:"_admin_data.js", out:"admin-checklist.html", key:"aajoo-admin-qa-v1",
  title:"Aajoo Admin Readiness", brand:"admin readiness", h1:"Admin system readiness",
  lede:"Every admin capability on Aajoo, grouped the way the panel is actually used — access, oversight, the catalogue, the money, and the content.",
  report:"# Aajoo admin testing — findings"
});
