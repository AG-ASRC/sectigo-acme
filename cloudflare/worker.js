export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "X-API-Token, Content-Type, Authorization",
      "Content-Type": "application/json",
    };

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    // Health check — pas d'auth
    if (url.pathname === "/health") {
      return new Response(JSON.stringify({ status: "ok" }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    // Tout le reste nécessite le token partagé
    const token = request.headers.get("X-API-Token");
    if (!token || token !== env.ACME_TOKEN) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: corsHeaders,
      });
    }

    // POST /dns — créer un TXT record _acme-challenge
    if (url.pathname === "/dns" && request.method === "POST") {
      let body;
      try {
        body = await request.json();
      } catch {
        return new Response(JSON.stringify({ error: "Invalid JSON" }), {
          status: 400, headers: corsHeaders,
        });
      }

      const fqdn = body.fqdn;
      const value = body.value;

      if (!fqdn || !value) {
        return new Response(JSON.stringify({ error: "fqdn and value required" }), {
          status: 400, headers: corsHeaders,
        });
      }

      // Sécurité : uniquement _acme-challenge
      if (!fqdn.startsWith("_acme-challenge.")) {
        return new Response(JSON.stringify({ error: "Only _acme-challenge allowed" }), {
          status: 403, headers: corsHeaders,
        });
      }

      const zoneName = fqdn.replace("_acme-challenge.", "");
      const recordName = fqdn;

      try {
        // Trouver le zone_id
        const zoneRes = await fetch(
          `https://api.cloudflare.com/client/v4/zones?name=${zoneName}`,
          {
            headers: {
              "Authorization": `Bearer ${env.CF_API_TOKEN}`,
              "Content-Type": "application/json",
            },
          }
        );
        const zoneData = await zoneRes.json();

        if (!zoneData.success || zoneData.result.length === 0) {
          return new Response(JSON.stringify({ error: "Zone not found: " + zoneName }), {
            status: 404, headers: corsHeaders,
          });
        }

        const zoneId = zoneData.result[0].id;

        // Vérifier si un TXT avec la même valeur existe déjà
        const listRes = await fetch(
          `https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records?type=TXT&name=${recordName}`,
          {
            headers: {
              "Authorization": `Bearer ${env.CF_API_TOKEN}`,
              "Content-Type": "application/json",
            },
          }
        );
        const listData = await listRes.json();

        if (listData.success) {
          const existing = listData.result.find(r => r.content === value);
          if (existing) {
            return new Response(
              JSON.stringify({ success: true, message: "Record already exists", record_id: existing.id }),
              { status: 200, headers: corsHeaders }
            );
          }
        }

        // Créer le record TXT
        const createRes = await fetch(
          `https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${env.CF_API_TOKEN}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              type: "TXT",
              name: recordName,
              content: value,
              ttl: 120,
            }),
          }
        );
        const createData = await createRes.json();

        if (!createData.success) {
          return new Response(
            JSON.stringify({
              error: "Create failed",
              details: createData.errors
            }),
            {
              status: 500,
              headers: corsHeaders
            }
          );
        }

        return new Response(JSON.stringify({ success: true, record_id: createData.result.id }), {
          status: 200, headers: corsHeaders,
        });

      } catch (err) {
        return new Response(JSON.stringify({ error: "API error", message: err.message }), {
          status: 500, headers: corsHeaders,
        });
      }
    }


    // DELETE /dns?fqdn=_acme-challenge.douarnenez.fr — supprimer le TXT
    if (url.pathname === "/dns" && request.method === "DELETE") {
      const body = await request.json();
      const fqdn = body.fqdn;
      const value = body.value;

      if (!fqdn) {
        return new Response(JSON.stringify({ error: "fqdn parameter required" }), {
          status: 400, headers: corsHeaders,
        });
      }

      if (!value) {
        return new Response(JSON.stringify({ error: "acme challenge value is required" }), {
          status: 400, headers: corsHeaders,
        });
      }

      if (!fqdn.startsWith("_acme-challenge.")) {
        return new Response(JSON.stringify({ error: "Only _acme-challenge allowed" }), {
          status: 403, headers: corsHeaders,
        });
      }

      const zoneName = fqdn.replace("_acme-challenge.", "");

      try {
        // Trouver le zone_id
        const zoneRes = await fetch(
          `https://api.cloudflare.com/client/v4/zones?name=${zoneName}`,
          {
            headers: {
              "Authorization": `Bearer ${env.CF_API_TOKEN}`,
              "Content-Type": "application/json",
            },
          }
        );
        const zoneData = await zoneRes.json();

        if (!zoneData.success || zoneData.result.length === 0) {
          return new Response(JSON.stringify({ error: "Zone not found: " + zoneName }), {
            status: 404, headers: corsHeaders,
          });
        }

        const zoneId = zoneData.result[0].id;

        // Lister les records TXT _acme-challenge
        const listRes = await fetch(
          `https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records?type=TXT&name=${fqdn}`,
          {
            headers: {
              "Authorization": `Bearer ${env.CF_API_TOKEN}`,
              "Content-Type": "application/json",
            },
          }
        );
        const listData = await listRes.json();

        if (!listData.success) {
          return new Response(JSON.stringify({ error: "List failed", details: listData.errors }), {
            status: 500, headers: corsHeaders,
          });
        }

        // Supprimer tous les records _acme-challenge trouvés
        const deleted = [];
        for (const record of listData.result) {

          if (record.content !== value) {
            continue;
          }
          const delRes = await fetch(
            `https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records/${record.id}`,
            {
              method: "DELETE",
              headers: {
                "Authorization": `Bearer ${env.CF_API_TOKEN}`,
              },
            }
          );
          const delData = await delRes.json();
          if (delData.success) {
            deleted.push(record.id);
          }
        }

        return new Response(JSON.stringify({success: true, fqdn, value, deleted: deleted.length}),{
          status: 200, headers: corsHeaders,
        });

      } catch (err) {
        return new Response(JSON.stringify({ error: "API error", message: err.message }), {
          status: 500, headers: corsHeaders,
        });
      }
    }

    // Route inconnue
    return new Response(JSON.stringify({ error: "Not found" }), {
      status: 404, headers: corsHeaders,
    });
  },
};