/* The rant tabs: write first, then (optionally) leave an email.
   The page sets <body data-tab="who|ai|influencers">. */
(function(){
  var SUPABASE_URL = "https://sxwhldbjizzeesexsurh.supabase.co";
  var ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4d2hsZGJqaXp6ZWVzZXhzdXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NTQzOTEsImV4cCI6MjA5NzIzMDM5MX0.gNrKElxIqDFQGE1_NIH2YJb5xtZaPebDJHXFoCk-jt4";
  var tab = document.body.getAttribute("data-tab");
  var $ = function(id){ return document.getElementById(id); };
  var rantId = null;

  function rpc(name, body){
    return fetch(SUPABASE_URL + "/rest/v1/rpc/" + name, {
      method:"POST", keepalive:true,
      headers:{ "Content-Type":"application/json", "apikey":ANON_KEY, "Authorization":"Bearer " + ANON_KEY },
      body: JSON.stringify(body)
    }).then(function(r){ return r.json().catch(function(){ return null; }).then(function(j){ if (!r.ok) throw new Error((j && j.message) || "Something broke."); return j; }); });
  }
  function show(id){ ["s-rant","s-thanks"].forEach(function(s){ $(s).classList.toggle("on", s === id); }); window.scrollTo(0,0); }

  $("take").addEventListener("input", function(){ $("send").disabled = $("take").value.trim() === ""; });

  $("rantform").onsubmit = function(e){
    e.preventDefault();
    var body = $("take").value.trim(); if (!body) return;
    var btn = $("send"); btn.disabled = true; btn.innerHTML = '<span class="spin"></span>One sec';
    rpc("submit_rant", { p: { tab: tab, body: body, user_agent: navigator.userAgent, website: $("website").value } })
      .then(function(id){ rantId = id; })
      .catch(function(){ rantId = null; })   // still thank them; the take is what they came to say
      .then(function(){ show("s-thanks"); });
  };

  var emailOk = function(v){ return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v.trim()); };
  $("email").addEventListener("input", function(){ $("sendmail").disabled = !emailOk($("email").value); });
  $("mailform").onsubmit = function(e){
    e.preventDefault();
    var v = $("email").value.trim(); if (!emailOk(v)) return;
    var btn = $("sendmail"); btn.disabled = true;
    var done = function(){ $("mailrow").hidden = true; $("mailok").hidden = false; };
    if (!rantId) { done(); return; }
    rpc("attach_rant_email", { p_id: rantId, p_email: v }).then(done).catch(function(err){
      $("mailerr").textContent = String(err && err.message || "Something broke."); btn.disabled = false;
    });
  };
})();
