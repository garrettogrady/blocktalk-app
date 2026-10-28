/* The quiz engine for blocktalk.nyc (regular) and /purist.
   The page sets <body data-quiz="regular|purist">. Points below are the
   page's local fallback only; the server recomputes every score from the
   option text (Supabase/00034) and never trusts this file. */
(function(){
  var SUPABASE_URL = "https://sxwhldbjizzeesexsurh.supabase.co";
  var ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4d2hsZGJqaXp6ZWVzZXhzdXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NTQzOTEsImV4cCI6MjA5NzIzMDM5MX0.gNrKElxIqDFQGE1_NIH2YJb5xtZaPebDJHXFoCk-jt4";

  var BANK = {
    city:      { title:"When you say “the city,” you mean:",
                 opts:[["The five boroughs",2],["Manhattan",2],["Manhattan, Brooklyn, and the parts of Queens I can reach without a transfer",1],["The five boroughs plus Long Island",0],["Other",1]],
                 textOn:"Other", placeholder:"go on…" },
    geo:       { title:"Does the answer to the previous question change depending on where you are geographically located at the time of answering?",
                 opts:[["No. The city is the city.",1],["Yes. Let me explain.",2]], textOn:"Yes. Let me explain.", placeholder:"explain yourself" },
    metrocard: { title:"A green MetroCard means:",
                 opts:[["Reduced fare for seniors",0],["The MTA's charitable giving program",0],["You are in high school",2],["Limited collector's edition",0]] },
    wsp:       { title:"Washington Square Park is:",
                 opts:[["NYU's campus",0],["Commissioned by Robert Moses as part of his 1939 open space program",0],["A gift from the French to the Duke of York",0],["A former potter's field with roughly 20,000 New Yorkers still buried under it",2]] },
    tokens:    { title:"Before the MetroCard, you paid for the subway with:",
                 opts:[["Dollar bills",0],["Quarters",0],["Tokens",2],["Paper tickets from the kiosk",0]] },
    brick:     { title:"What does “it's brick outside” mean?",
                 opts:[["It's snowing very heavily",0],["There is construction on the street",0],["It's cold outside",2]] },
    shsat:     { title:"What is the SHSAT?",
                 opts:[["An STD",0],["South of Houston Street after Thompson",0],["A test",2],["Who cares",1]] },
    katz:      { title:"Price of a pastrami sandwich from Katz's in 2005:",
                 opts:[["$9.75",0],["$12.95",0],["$17.50",0]] },
    dimes:     { title:"What is Dimes Square?",
                 opts:[["A place for all the delusional people in the city to congregate",1],["It doesn't exist",1],["A place where people go out, but if you're employed they won't let you into the bars",1],["Other",1]],
                 textOn:"Other", placeholder:"go on…" },
    hood_change:{ title:"If you could change anything about this neighborhood, what would it be?", opts:[], freeOnly:true, placeholder:"optional" },
    nj:        { title:"New Jersey.", opts:[], freeOnly:true, placeholder:"optional" }
  };
  var QUIZZES = {
    regular: { keys:["city","geo","metrocard","tokens","brick","dimes","hood_change","nj"], max:11, bands:[10,7,4] },
    purist:  { keys:["city","geo","metrocard","wsp","tokens","brick","shsat","katz","dimes","hood_change","nj"], max:17, bands:[15,10,6] }
  };
  var FLAVOR = {
    "CITY SLICKER":"Okay, you actually might be native. Check your texts.",
    "BLOCKTALKER":"Cheers, it's not your first day on earth. You do seem to know the city.",
    "TRANSPLANT":"No way, you moved here? Damn, that's crazy.",
    "TOURIST":"Welcome to the city, asshole. Don't walk so slowly, and if you're in a group, don't take up the whole sidewalk."
  };
  var TIER_CLASS = { "CITY SLICKER":"t-cs", "BLOCKTALKER":"t-bt", "TRANSPLANT":"t-tr", "TOURIST":"t-to" };

  var quizName = document.body.getAttribute("data-quiz") === "purist" ? "purist" : "regular";
  var quiz = QUIZZES[quizName];
  var Q = quiz.keys.map(function(k){ var q = Object.assign({ key:k }, BANK[k]); return q; });
  var N = Q.length;

  var src = (new URLSearchParams(location.search).get("src") || "direct").toLowerCase();
  if (["p1","p2","p3"].indexOf(src) < 0) src = "direct";
  var answers = {};
  var i = 0;

  var $ = function(id){ return document.getElementById(id); };
  var screens = ["s-intro","s-q","s-capture","s-verdict"];
  // The rant tabs are an exit; once the quiz starts they go away until the verdict.
  var tabs = document.querySelector(".tabs");
  function show(id){
    screens.forEach(function(s){ $(s).classList.toggle("on", s === id); });
    if (tabs) tabs.hidden = (id === "s-q" || id === "s-capture");
    window.scrollTo(0,0);
  }
  function progress(step){ // 0 intro, 1..N questions, N+1 capture, N+2 verdict
    $("bar").style.width = Math.round(step / (N + 2) * 100) + "%";
    $("count").textContent = step >= 1 && step <= N ? (step + " / " + N) : (step === N + 1 ? "ALMOST" : "");
  }

  function rpc(name, body){
    return fetch(SUPABASE_URL + "/rest/v1/rpc/" + name, {
      method:"POST", keepalive:true,
      headers:{ "Content-Type":"application/json", "apikey":ANON_KEY, "Authorization":"Bearer " + ANON_KEY },
      body: JSON.stringify(body)
    });
  }

  // One scan per visit per tab on the landing page only, so a refresh doesn't double count.
  if (quizName === "regular") {
    try {
      if (!sessionStorage.getItem("bt_scan")) {
        sessionStorage.setItem("bt_scan", "1");
        rpc("log_survey_scan", { p_src: src, p_user_agent: navigator.userAgent }).catch(function(){});
      }
    } catch (e) { rpc("log_survey_scan", { p_src: src, p_user_agent: navigator.userAgent }).catch(function(){}); }
  }

  function renderQ(){
    var q = Q[i], a = answers[q.key] || {};
    $("q-title").textContent = q.title;
    var box = $("q-opts"); box.innerHTML = "";
    q.opts.forEach(function(o){
      var b = document.createElement("button");
      b.type = "button"; b.className = "opt" + (a.choice === o[0] ? " sel" : ""); b.textContent = o[0];
      b.onclick = function(){
        answers[q.key] = { choice:o[0], text:(answers[q.key]||{}).text || "" };
        renderQ();
        if (q.textOn === o[0]) { $("q-text").focus(); }
      };
      box.appendChild(b);
    });
    var t = $("q-text");
    t.value = a.text || "";
    t.placeholder = q.placeholder || "";
    var wantText = q.freeOnly || (q.textOn && a.choice === q.textOn);
    t.className = wantText ? "on" : "hide";
    t.oninput = function(){ answers[q.key] = { choice:(answers[q.key]||{}).choice || null, text:t.value }; };
    $("next").disabled = !(q.freeOnly || a.choice);
    $("next").innerHTML = (i === N - 1) ? "Finish &rarr;" : "Next &rarr;";
    progress(i + 1);
  }

  $("start").onclick = function(){ i = 0; renderQ(); show("s-q"); };
  $("next").onclick = function(){
    if (i < N - 1) { i++; renderQ(); }
    else { show("s-capture"); progress(N + 1); validate(); }
  };
  $("back").onclick = function(){ if (i === 0) { show("s-intro"); progress(0); } else { i--; renderQ(); } };
  $("back2").onclick = function(){ i = N - 1; renderQ(); show("s-q"); };

  var emailOk = function(v){ return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v.trim()); };
  // Neighborhood: the app's full list (neighborhoods.js), searched as you type.
  // `picked` is the only value that counts; typing again clears it.
  var HOODS = (window.BT_HOODS || []).concat([["Not NYC (yet)", ""]]);
  var picked = "";
  function hoodMatches(q){
    q = q.trim().toLowerCase();
    if (!q) return HOODS.slice(0, 8);
    var starts = [], has = [];
    HOODS.forEach(function(h){ var n = h[0].toLowerCase(); if (n.indexOf(q) === 0) starts.push(h); else if (n.indexOf(q) >= 0 || h[1].toLowerCase() === q) has.push(h); });
    var out = starts.concat(has).slice(0, 8);
    if (!out.some(function(h){ return h[0] === "Not NYC (yet)"; })) out.push(["Not NYC (yet)", ""]);
    return out;
  }
  function renderHoods(){
    var list = $("hoodlist"); list.innerHTML = "";
    hoodMatches($("hood").value).forEach(function(h){
      var li = document.createElement("li"); if (!h[1]) li.className = "none";
      li.innerHTML = "<span></span><small></small>"; li.firstChild.textContent = h[0]; li.lastChild.textContent = h[1];
      li.onmousedown = function(e){ e.preventDefault(); pickHood(h[0]); };
      list.appendChild(li);
    });
    list.hidden = false;
  }
  function pickHood(name){ picked = name; $("hood").value = name; $("hood").classList.add("picked"); $("hoodlist").hidden = true; validate(); }
  $("hood").addEventListener("focus", renderHoods);
  $("hood").addEventListener("input", function(){ picked = ""; $("hood").classList.remove("picked"); renderHoods(); validate(); });
  $("hood").addEventListener("blur", function(){ setTimeout(function(){ $("hoodlist").hidden = true; }, 120); });
  $("hood").addEventListener("keydown", function(e){ if (e.key === "Enter") { e.preventDefault(); var first = $("hoodlist").querySelector("li"); if (first) pickHood(first.firstChild.textContent); } });
  function validate(){
    var ok = emailOk($("email").value) && picked !== "";
    $("submit").disabled = !ok;
    $("smsrow").hidden = $("phone").value.trim() === "";
  }
  ["email","phone"].forEach(function(id){ $(id).addEventListener("input", validate); $(id).addEventListener("change", validate); });

  function localScore(){
    var s = 0;
    Q.forEach(function(q){ var a = answers[q.key] || {}; if (!a.choice) return;
      q.opts.forEach(function(o){ if (o[0] === a.choice) s += o[1]; }); });
    return s;
  }
  function localTier(score){
    return score >= quiz.bands[0] ? "CITY SLICKER" : score >= quiz.bands[1] ? "BLOCKTALKER" : score >= quiz.bands[2] ? "TRANSPLANT" : "TOURIST";
  }
  function fitTier(){
    var el = $("v-tier"); var size = 66; var max = Math.min(66, window.innerWidth * 0.13);
    el.style.fontSize = max + "px";
    var guard = 0;
    while (el.scrollWidth > el.clientWidth && size > 22 && guard++ < 40) { size = Math.min(size, max) - 2; el.style.fontSize = size + "px"; }
  }
  window.addEventListener("resize", function(){ if ($("s-verdict").classList.contains("on")) fitTier(); });

  function verdict(score, max, tier){
    tier = tier || localTier(score);
    document.querySelector(".card").className = "card " + TIER_CLASS[tier];
    $("v-tier").textContent = tier;
    $("v-score").textContent = score + " / " + max;
    $("v-flavor").textContent = FLAVOR[tier];
    lastVerdict = tier;
    show("s-verdict"); progress(N + 2); fitTier();
  }

  // Share: the native iOS/Android share sheet where it exists, copy the link elsewhere.
  var lastVerdict = null;
  $("share").onclick = function(){
    var url = "https://blocktalk.nyc/";
    var text = (lastVerdict ? "I got " + lastVerdict + ". " : "") + "Think you're a New Yorker? Prove it.";
    var hint = $("sharehint");
    if (navigator.share) {
      navigator.share({ title: "Think you're a New Yorker? Prove it.", text: text, url: url }).catch(function(){});
    } else if (navigator.clipboard) {
      navigator.clipboard.writeText(text + " " + url).then(function(){ hint.textContent = "Link copied."; }, function(){ hint.textContent = url; });
    } else { hint.textContent = url; }
  };

  $("capture").onsubmit = function(e){
    e.preventDefault();
    validate(); if ($("submit").disabled) return;
    var btn = $("submit"); btn.disabled = true; btn.innerHTML = '<span class="spin"></span>One sec';
    $("err").textContent = "";
    var payload = {
      quiz: quizName, src: src, answers: answers,
      email: $("email").value.trim(), neighborhood: picked,
      phone: $("phone").value.trim() || null,
      sms_consent: $("phone").value.trim() !== "" && $("sms").checked,
      user_agent: navigator.userAgent,
      website: $("website").value
    };
    rpc("submit_survey_response", { p: payload }).then(function(r){
      return r.json().then(function(j){ return { ok: r.ok, j: j }; });
    }).then(function(x){
      if (!x.ok) { throw new Error((x.j && x.j.message) || "Something broke."); }
      verdict(x.j.score, x.j.max, x.j.tier);
    }).catch(function(err){
      var msg = String(err && err.message || "");
      // Our own refusals are written for the user; anything else, show the
      // verdict anyway rather than lose them at the last step.
      if (/email|neighborhood/i.test(msg)) { $("err").textContent = msg; btn.disabled = false; btn.innerHTML = "Get my verdict &rarr;"; }
      else { verdict(localScore(), quiz.max, null); }
    });
  };

  progress(0);
})();
