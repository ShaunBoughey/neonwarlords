# Minimal Meshy REST client. Key comes from the MESHY_API_KEY env var only; never printed.
import sys, os, json, base64, time, urllib.request
API = "https://api.meshy.ai/openapi/v1/"
KEY = os.environ["MESHY_API_KEY"]

def call(method, path, body=None):
    req = urllib.request.Request(API + path, method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": "Bearer " + KEY, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read() or b"{}")

def data_uri(path):
    ext = path.rsplit(".", 1)[-1].lower().replace("jpg", "jpeg")
    return "data:image/%s;base64,%s" % (ext, base64.b64encode(open(path, "rb").read()).decode())

def wait(path, tid):
    while True:
        t = call("GET", path + "/" + tid)
        if t["status"] in ("SUCCEEDED", "FAILED", "CANCELED"):
            return t
        time.sleep(15)

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "balance":
        print(call("GET", "balance"))
    elif cmd == "i23d":   # i23d <image> <out_json>
        body = {"image_url": data_uri(sys.argv[2]), "ai_model": "latest", "pose_mode": "t-pose",
                "should_texture": True, "enable_pbr": True, "texture_resolution": "2k",
                "should_remesh": True, "topology": "triangle", "target_polycount": 40000,
                "target_formats": ["glb", "fbx"], "multi_view_thumbnails": True}
        tid = call("POST", "image-to-3d", body)["result"]
        print("task", tid, flush=True)
        t = wait("image-to-3d", tid)
        json.dump(t, open(sys.argv[3], "w"), indent=1)
        print(t["status"], t.get("task_error"), t.get("consumed_credits"))
    elif cmd == "i23d_st":   # i23d_st <image> <polycount> <out_json>  (Smart Topology meshy-t2.5)
        body = {"image_url": data_uri(sys.argv[2]), "model_type": "smart-topology", "ai_model": "meshy-t2.5",
                "pose_mode": "t-pose", "should_texture": True, "enable_pbr": True, "texture_resolution": "2k",
                "target_polycount": int(sys.argv[3]), "target_formats": ["glb", "fbx"], "multi_view_thumbnails": True}
        tid = call("POST", "image-to-3d", body)["result"]
        print("task", tid, flush=True)
        t = wait("image-to-3d", tid)
        json.dump(t, open(sys.argv[4], "w"), indent=1)
        print(t["status"], t.get("task_error"), t.get("consumed_credits"))
    elif cmd == "i2i":    # i2i <image> <model> <prompt_file> <out_json>
        body = {"ai_model": sys.argv[3], "prompt": open(sys.argv[4], encoding="utf-8").read().strip(),
                "reference_image_urls": [data_uri(sys.argv[2])], "aspect_ratio": "1:1"}
        tid = call("POST", "image-to-image", body)["result"]
        print("task", tid, flush=True)
        t = wait("image-to-image", tid)
        json.dump(t, open(sys.argv[5], "w"), indent=1)
        print(t["status"], t.get("task_error"), t.get("consumed_credits"))
        for i, u in enumerate(t.get("image_urls") or []):
            urllib.request.urlretrieve(u, sys.argv[5].replace(".json", "_%d.png" % i))
    elif cmd == "rig":    # rig <input_task_id> <height_m> <out_json>
        tid = call("POST", "rigging", {"input_task_id": sys.argv[2], "height_meters": float(sys.argv[3])})["result"]
        print("task", tid, flush=True)
        t = wait("rigging", tid)
        json.dump(t, open(sys.argv[4], "w"), indent=1)
        print(t["status"], t.get("task_error"), t.get("consumed_credits"))
    elif cmd == "anim":   # anim <rig_task_id> <id,id,...> <out_json>
        ids = [int(x) for x in sys.argv[3].split(",")]
        tid = call("POST", "animations", {"rig_task_id": sys.argv[2], "action_ids": ids,
                   "post_process": {"operation_type": "change_fps", "fps": 30}})["result"]
        print("task", tid, flush=True)
        t = wait("animations", tid)
        json.dump(t, open(sys.argv[4], "w"), indent=1)
        print(t["status"], t.get("task_error"), t.get("consumed_credits"))
    elif cmd == "dl":     # dl <url> <path>  (signed asset URL; no key sent)
        urllib.request.urlretrieve(sys.argv[2], sys.argv[3])
        print(sys.argv[3], os.path.getsize(sys.argv[3]))
    elif cmd == "get":    # get <kind> <id>
        print(json.dumps(call("GET", sys.argv[2] + "/" + sys.argv[3]), indent=1)[:3000])
