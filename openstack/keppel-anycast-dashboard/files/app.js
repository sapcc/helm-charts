(() => {

  const $ = (selector) => document.querySelector(selector);
  const $$ = (selector) => Array.from(document.querySelectorAll(selector));

  const parseError = (response) => {
    return response.text()
      .then((text) => { throw new Error(text); })
      .catch((error) => { throw new Error(`HTTP ${response.status} (${response.statusText}): ${error}`); });
  };

  const promURL = $("body").dataset.prometheusUrl;
  const getMetrics = (query) => {
    const url = new URL(promURL);
    url.searchParams.set("query", query);
    return fetch(url.toString())
      .then(async (response) => {
        if (!response.ok) {
          await parseError(response);
        }
        return response.json();
      })
      .then((payload) => {
        if (payload.status !== "success") {
          console.log({ payloadWas: payload });
          throw new Error(`unexpected status in API response: ${JSON.stringify(payload.status)}`);
        }
        if (payload.data.resultType !== "vector") {
          console.log({ payloadWas: payload });
          throw new Error(`unexpected data.resultType in API response: ${JSON.stringify(payload.data.resultType)}`);
        }
        return payload.data.result;
      })
      .catch((error) => {
        const msg = `cannot read metrics for <code>${query}</code>: ${error}`;
        const p = document.createElement("p");
        p.innerHTML = msg;
        p.classList.add("error");
        $("div#messages").appendChild(p);
      });
  };

  const promise1 = getMetrics(`max by (region) (keppel_anycastmonitor_membership{region!~"qa.*"})`).then((results) => {
    const valueForRegion = {};
    for (const result of results) {
      const region = result.metric["region"];
      if (typeof region !== "string") {
        continue;
      }
      valueForRegion[region] = (result.value || [])[1] || "MISSING";
    }
    for (const td of $$("td.member")) {
      const region = td.closest("tr").dataset.region;
      const value = valueForRegion[region];
      td.innerText = value;
      td.classList.toggle("success", value === "1");
      td.classList.toggle("failed", value !== "1");
    }
  });

  const promise2 = getMetrics(`max by (account, region) (keppel_anycastmonitor_result{region!~"qa.*"})`).then((results) => {
    const valueForRegionAndAccount = {};
    for (const result of results) {
      const region = result.metric["region"];
      if (typeof region !== "string") {
        continue;
      }
      valueForRegionAndAccount[region] ||= {};
      const account = result.metric["account"];
      if (typeof account !== "string") {
        continue;
      }
      valueForRegionAndAccount[region][account] = (result.value || [])[1] || "MISSING";
    }
    for (const td of $$("td.reach")) {
      const region = td.closest("tr").dataset.region;
      const account = td.dataset.account;
      const value = valueForRegionAndAccount[region][account];
      td.innerText = value;
      td.classList.toggle("success", value === "1");
      td.classList.toggle("failed", value !== "1");
    }
  });

  Promise.all([promise1, promise2]).then(() => {
    $("p.loading").remove();
  });

})();
