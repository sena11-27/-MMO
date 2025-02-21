import processing.net.*;

int screenWidth = 800;
int screenHeight = 800;
int gameWidth = 1000;
int gameHeight = 1000;

class Player {
  int id;
  float cx, cy;
  float targetX, targetY;
  float speed = 2;
  String currentStage = "default";
  HashMap<String, String> stageBackgrounds = new HashMap<>();
  String characterType = "male";

  Player(int id) {
    this.id = id;
    this.cx = random(gameWidth);
    this.cy = random(gameHeight);
    this.targetX = this.cx;
    this.targetY = this.cy;
    stageBackgrounds.put("default", "default.png");
    stageBackgrounds.put("mountain", "mountain.jpg");
    stageBackgrounds.put("forest", "forest.jpg");
  }

  void move(float dx, float dy) {
    this.targetX = cx + dx;
    this.targetY = cy + dy;
    checkStageTransition();
  }

  void moveToTarget() {
    if (dist(cx, cy, targetX, targetY) > speed) {
      float angle = atan2(targetY - cy, targetX - cx);
      cx += cos(angle) * speed;
      cy += sin(angle) * speed;
    } else {
      cx = targetX;
      cy = targetY;
    }
    checkStageTransition();
  }

  void checkStageTransition() {
    if (cx < 0 && currentStage == "default") {
      currentStage = "mountain";
      cx += gameWidth;
    } else if (cx >= gameWidth && currentStage == "mountain") {
      currentStage = "default";
      cx -= gameWidth;
    } else if (cy < 0 && currentStage == "default") {
      currentStage = "forest";
      cy += gameHeight;
    } else if (cy >= gameHeight && currentStage == "forest") {
      currentStage = "default";
      cy -= gameHeight;
    }
  }

  JSONObject toJSON() {
    JSONObject item = new JSONObject();
    item.setInt("id", this.id);
    item.setFloat("x", this.cx);
    item.setFloat("y", this.cy);
    item.setString("stage", this.currentStage);
    item.setString("backgroundImage", stageBackgrounds.get(currentStage));
    item.setString("characterType", this.characterType);
    return item;
  }
}

ArrayList<NPC> npcs = new ArrayList<>();

class NPC {
  int id;
  float x, y;
  String message;

  NPC(int id, float x, float y, String message) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.message = message;
  }

  JSONObject toJSON() {
    JSONObject obj = new JSONObject();
    obj.setInt("id", id);
    obj.setFloat("x", x);
    obj.setFloat("y", y);
    obj.setString("message", message);
    return obj;
  }
}

HashMap<String, ArrayList<Enemy>> stageEnemies = new HashMap<>();
String[] enemyTypes = {"gob1.png", "gob2.png", "gob3.png"};
class Enemy {
  int id;
  float x, y;
  String type;
  int hp;
  int maxHp;

  Enemy(int id, float x, float y, String type) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.type = type;

    if (type.equals("gob1.png")) {
      this.maxHp = 10;
    } else if (type.equals("gob2.png")) {
      this.maxHp = 20;
    } else if (type.equals("gob3.png")) {
      this.maxHp = 30;
    }
    this.hp = this.maxHp;
  }

  JSONObject toJSON() {
    JSONObject obj = new JSONObject();
    obj.setInt("id", id);
    obj.setFloat("x", x);
    obj.setFloat("y", y);
    obj.setString("type", type);
    obj.setInt("hp", hp);
    obj.setInt("maxHp", maxHp);
    return obj;
  }
}

Server server;
int idOffset = 0;
HashMap<Client, Player> players = new HashMap<>();

void setup() {
  server = new Server(this, 5204);
  npcs.add(new NPC(1, 200, 200, "Hello!"));
  npcs.add(new NPC(2, 400, 400, "fight!"));
  npcs.add(new NPC(3, 600, 600, "...."));
  npcs.add(new NPC(4, 800, 800, "Hungry"));

  stageEnemies.put("mountain", new ArrayList<Enemy>());
  stageEnemies.put("forest", new ArrayList<Enemy>());

  for (int i = 0; i < 10; i++) {
    stageEnemies.get("mountain").add(new Enemy(i, random(gameWidth), random(gameHeight), enemyTypes[int(random(3))]));
    stageEnemies.get("forest").add(new Enemy(i + 10, random(gameWidth), random(gameHeight), enemyTypes[int(random(3))]));
  }
}


void draw() {
  for (Client client : players.keySet()) {
    Player player = players.get(client);
    player.moveToTarget();

    JSONArray playerArray = new JSONArray();
    for (Player p : players.values()) {
      if (player.cx - screenWidth / 2 <= p.cx
        && p.cx <= player.cx + screenWidth / 2
        && player.cy - screenHeight / 2 <= p.cy
        && p.cy <= player.cy + screenHeight / 2) {
        playerArray.append(p.toJSON());
      }
    }

    JSONArray enemyArray = new JSONArray();
    if (stageEnemies.containsKey(player.currentStage) && stageEnemies.get(player.currentStage) != null) {
      for (Enemy enemy : stageEnemies.get(player.currentStage)) {
        enemyArray.append(enemy.toJSON());
      }
    }


    JSONArray npcArray = new JSONArray();
    if (player.currentStage.equals("default")) {
      for (NPC npc : npcs) {
        npcArray.append(npc.toJSON());
      }
    }

    JSONObject message = new JSONObject();
    message.setJSONArray("players", playerArray);
    message.setJSONArray("npcs", npcArray);
    message.setJSONArray("enemies", enemyArray);
    message.setFloat("cx", player.cx);
    message.setFloat("cy", player.cy);
    message.setString("stage", player.currentStage);
    message.setString("characterType", player.characterType);
    client.write(message.toString());
    client.write('\0');
  }
}

void clientEvent(Client client) {
  String payload = client.readStringUntil('\0');
  if (payload != null) {
    JSONObject message = parseJSONObject(payload.substring(0, payload.length() - 1));
    Player player = players.get(client);

    if (message.hasKey("action") && message.getString("action").equals("start")) {
      startGameForPlayer(player);
    }

    if (message.hasKey("direction")) {
      float d = 20;
      switch (message.getString("direction")) {
      case "left":
        player.move(-d, 0);
        break;
      case "right":
        player.move(d, 0);
        break;
      case "up":
        player.move(0, -d);
        break;
      case "down":
        player.move(0, d);
        break;
      }
    }
    if (message.hasKey("targetX") && message.hasKey("targetY")) {
      float targetX = message.getFloat("targetX");
      float targetY = message.getFloat("targetY");
      player.targetX = constrain(targetX, 0, gameWidth);
      player.targetY = constrain(targetY, 0, gameHeight);
    }
    if (message.hasKey("characterType")) {
      player.characterType = message.getString("characterType");
    }

    if (message.hasKey("attack") && message.getString("attack").equals("melee")) {
      attackEnemy(player);
    }
  }
}

synchronized void attackEnemy(Player player) {
  if (stageEnemies.containsKey(player.currentStage)) {
    ArrayList<Enemy> enemies = stageEnemies.get(player.currentStage);
    for (int i = enemies.size() - 1; i >= 0; i--) {
      Enemy enemy = enemies.get(i);
      if (dist(player.cx, player.cy, enemy.x, enemy.y) < 50) {
        enemy.hp -= 5; 

        if (enemy.hp <= 0) {
          enemies.remove(i);
        }
      }
    }
  }
}


void startGameForPlayer(Player player) {
  player.cx = random(gameWidth);
  player.cy = random(gameHeight);
  player.targetX = player.cx;
  player.targetY = player.cy;
  player.currentStage = "default";
}

void serverEvent(Server server, Client client) {
  Player player = new Player(idOffset++);
  players.put(client, player);
}

void disconnectEvent(Client client) {
  players.remove(client);
}
