(function(){
  const c = window.BYE_CONFIG || {};
  const $ = (s)=>document.querySelector(s);
  const wa = (message)=>`https://wa.me/${c.phoneDigits || ""}?text=${encodeURIComponent(message || "Hi BYE FASHIONS, I'd like to know more about your collections.")}`;
  const links = {
    whatsapp: wa(),
    whatsappGroup: c.whatsappGroup || wa("Hi BYE FASHIONS, please share your WhatsApp collections group invite link."),
    instagram: c.instagram || "#",
    facebook: c.facebook || "#",
    youtube: c.youtube || "#",
    linktree: c.linktree || "#",
    maps: "https://www.google.com/maps/search/?api=1&query="+encodeURIComponent(c.address || "BYE FASHIONS Madanapalle")
  };
  document.querySelectorAll("[data-link]").forEach(a=>{
    const key=a.dataset.link; a.href=links[key] || "#";
    if(a.href!=="#" && !a.href.endsWith("#")){a.target="_blank";a.rel="noopener noreferrer";}
    if((key==="linktree" && !c.linktree)||(key==="whatsappGroup" && !c.whatsappGroup)){
      a.addEventListener("click",e=>{
        if(key==="linktree"){e.preventDefault();alert("Add your Linktree URL in config.js first.");}
        if(key==="whatsappGroup"){e.preventDefault();alert("Add your WhatsApp group invite link in config.js first. You can still contact the shop directly on WhatsApp.");}
      });
    }
  });
  document.querySelectorAll("[data-wa-message]").forEach(a=>{a.href=wa(a.dataset.waMessage);a.target="_blank";a.rel="noopener noreferrer";});
  $("#shopAddress").textContent=c.address || "";
  $("#shopPhone").textContent=c.phoneDisplay || "";
  $("#shopPhone").href="tel:+"+(c.phoneDigits || "");
  $("#shopEmail").textContent=c.email || "";
  $("#shopEmail").href="mailto:"+(c.email || "");
  $("#announcement").textContent=c.announcement || "WELCOME TO BYE FASHIONS";

  function youtubeEmbed(url){
    if(!url) return "";
    try{
      const u=new URL(url);
      let id="";
      if(u.hostname.includes("youtu.be")) id=u.pathname.slice(1);
      else if(u.hostname.includes("youtube.com")) id=u.searchParams.get("v") || (u.pathname.includes("/embed/") ? u.pathname.split("/embed/")[1] : "");
      return id ? "https://www.youtube-nocookie.com/embed/"+id.split(/[?&/]/)[0] : "";
    }catch(e){return "";}
  }
  [["promoVideo1",c.promoVideo1],["promoVideo2",c.promoVideo2]].forEach(([id,url])=>{
    const host=document.getElementById(id), embed=youtubeEmbed(url);
    if(host && embed){
      host.innerHTML="";
      const frame=document.createElement("iframe");
      frame.src=embed; frame.title="BYE FASHIONS promotional video";
      frame.loading="lazy"; frame.allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share";
      frame.allowFullscreen=true; frame.referrerPolicy="strict-origin-when-cross-origin";
      frame.style.cssText="width:100%;height:100%;min-height:260px;border:0;position:absolute;inset:0";
      host.style.position="relative";host.style.paddingTop="56.25%";host.appendChild(frame);
    }
  });

  $("#year").textContent=new Date().getFullYear();
  const toggle=$("#menuToggle"), nav=$("#mainNav");
  toggle.addEventListener("click",()=>{const open=nav.classList.toggle("open");toggle.setAttribute("aria-expanded",String(open));});
  nav.querySelectorAll("a").forEach(a=>a.addEventListener("click",()=>nav.classList.remove("open")));
})();