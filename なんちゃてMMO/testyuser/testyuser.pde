import processing.net.*;

int playerSize = 50;
int gameWidth = 1000;
int gameHeight = 1000;
boolean onTitleScreen = true;
boolean isMaleSelected = false;
boolean isFemaleSelected = false;
PImage maleImage, femaleImage, npcImage;

Client client;
Button startButton, maleButton, femaleButton;

JSONObject status = new JSONObject();
HashMap<String, PImage> stageBackgrounds = new HashMap<>();
HashMap<String, PImage> enemyImages = new HashMap<>();

void setup() {
  size(800, 800);
  client = new Client(this, "127.0.0.1", 5204);

  maleImage = loadImage("male.png");
  femaleImage = loadImage("female.png");
  npcImage = loadImage("npc.png");

  stageBackgrounds.put("default", loadImage("default.png"));
  stageBackgrounds.put("mountain", loadImage("mountain.jpg"));
  stageBackgrounds.put("forest", loadImage("forest.jpg"));
  enemyImages.put("gob1.png", loadImage("gob1.png"));
  enemyImages.put("gob2.png", loadImage("gob2.png"));
  enemyImages.put("gob3.png", loadImage("gob3.png"));

  startButton = new Button("Start", width / 2 - 50, height / 2 + 100, 100, 50);
  maleButton = new Button("Male", width / 2 - 100, height / 2, 100, 50);
  femaleButton = new Button("Female", width / 2 + 20, height / 2, 100, 50);
}

void draw() {
  background(255);

  if (onTitleScreen) {
    drawTitleScreen();
  } else {
    if (status.getJSONArray("players") == null) {
      return;
    }

    synchronized (status) {
      String stage;
      if (status.hasKey("stage")) {
        stage = status.getString("stage");
      } else {
        stage = "default";
      }

      if (stageBackgrounds.containsKey(stage)) {
        PImage bg = stageBackgrounds.get(stage);

        pushMatrix();
        
        float cx = status.getFloat("cx");
        float cy = status.getFloat("cy");
        translate(-cx + width / 2, -cy + height / 2);
        image(bg, 500, 500, gameWidth, gameHeight);
        
        popMatrix();
        
      } else {
        background(255);
      }

      drawGameWorld();
    }
  }
}


void drawTitleScreen() {
  background(255);

  fill(0);
  textSize(48);
  textAlign(CENTER, CENTER);
  text("MMORPG Game", width / 2, height / 2 - 150);

  startButton.display();
  maleButton.display();
  femaleButton.display();
}

void drawGameWorld() {
  pushMatrix();

  float cx = status.getFloat("cx");
  float cy = status.getFloat("cy");
  translate(-cx + width / 2, -cy + height / 2);
  drawField();
  drawPlayers();
  if (status.hasKey("stage") && status.getString("stage").equals("default")) {
    drawNPCs();
  }
  if (status.hasKey("stage") && status.getString("stage").equals("mountain")) {
    drawEnemies();
  }
  if (status.hasKey("stage") && status.getString("stage").equals("forest")) {
    drawEnemies();
  }
  
  popMatrix();
}

void drawNPCs() {
  if (!status.hasKey("stage") || !status.getString("stage").equals("default")) {
    return;
  }

  JSONArray npcs = status.getJSONArray("npcs");
  float playerX = status.getFloat("cx");
  float playerY = status.getFloat("cy");

  for (int i = 0; i < npcs.size(); i++) {
    JSONObject npc = npcs.getJSONObject(i);
    float npcX = npc.getFloat("x");
    float npcY = npc.getFloat("y");
    String message = npc.getString("message");

    image(npcImage, npcX, npcY, 50, 50);

    if (dist(playerX, playerY, npcX, npcY) < 100) {
      fill(255);
      rectMode(CENTER);
      rect(npcX, npcY - 35, 50, 25);
      fill(0);
      textAlign(CENTER);
      textSize(20);
      text(message, npcX, npcY - 30);
    }
  }
}

void drawEnemies() {
  if (!status.hasKey("enemies")) return;

  JSONArray enemies = status.getJSONArray("enemies");

  for (int i = 0; i < enemies.size(); i++) {
    JSONObject enemy = enemies.getJSONObject(i);
    float enemyX = enemy.getFloat("x");
    float enemyY = enemy.getFloat("y");
    String enemyType = enemy.getString("type");
    int hp = enemy.getInt("hp");
    int maxHp = enemy.getInt("maxHp");

    PImage enemyImage = enemyImages.get(enemyType);
    if (enemyImage != null) {
      image(enemyImage, enemyX, enemyY, 50, 50);
    } else {
      fill(255, 0, 0);
      ellipse(enemyX, enemyY, 40, 40);
    }

    float hpBarWidth = 40 * ((float) hp / maxHp);
    fill(255, 0, 0);
    rect(enemyX - 20, enemyY - 30, hpBarWidth, 5);
    fill(0);
    rect(enemyX - 20 + hpBarWidth, enemyY - 30, 40 - hpBarWidth, 5);
  }
}


void drawField() {
  int size = 100;
  int n = gameWidth / size;
  stroke(0);

  for (int i = 0; i <= n; i++) {
    line(0, size * i, gameWidth, size * i);
  }

  for (int j = 0; j <= n; j++) {
    line(size * j, 0, size * j, gameHeight);
  }

  if (status.hasKey("stage") && status.getString("stage").equals("default")) {
    fill(0);
    textSize(30);
    textAlign(CENTER);
    text("← Mountain", -50, gameHeight / 2);
    text("↑ Forest", gameWidth / 2, -50);
    text("No area", gameWidth + 50, gameHeight / 2);
    text("No area", gameWidth / 2, gameHeight + 50);
  } else if (status.hasKey("stage") && status.getString("stage").equals("mountain")) {
    fill(0);
    textSize(30);
    textAlign(CENTER);
    text("Go home →", gameWidth + 80, gameHeight / 2);
  } else if (status.hasKey("stage") && status.getString("stage").equals("forest")) {
    fill(0);
    textSize(30);
    textAlign(CENTER);
    text("Go home ↓", gameWidth / 2, gameHeight + 50);
  }
}


void drawPlayers() {
  JSONArray players = status.getJSONArray("players");

  for (int i = 0; i < players.size(); i++) {
    JSONObject player = players.getJSONObject(i);
    float playerX = player.getFloat("x");
    float playerY = player.getFloat("y");
    String characterType = player.getString("characterType");

    imageMode(CENTER);
    if (characterType.equals("male")) {
      image(maleImage, playerX, playerY, playerSize, playerSize);
    } else {
      image(femaleImage, playerX, playerY, playerSize, playerSize);
    }
  }
}


void keyPressed() {
  if (onTitleScreen) return;

  JSONObject message = new JSONObject();

  switch (key) {
  case 'w':
    message.setString("direction", "up");
    break;
  case 'a':
    message.setString("direction", "left");
    break;
  case 's':
    message.setString("direction", "down");
    break;
  case 'd':
    message.setString("direction", "right");
    break;
  case ' ':
    message.setString("attack", "melee");
    break;
  }

  sendMessageToServer(message);
}

void mousePressed() {
  if (onTitleScreen) {
    if (startButton.isMouseOver()) {
      onTitleScreen = false;
    }
    if (maleButton.isMouseOver()) {
      isMaleSelected = true;
      isFemaleSelected = false;
      maleButton.setTextColor(color(0, 0, 255));
      femaleButton.setTextColor(color(0));
      sendCharacterSelection("male");
    }
    if (femaleButton.isMouseOver()) {
      isFemaleSelected = true;
      isMaleSelected = false;
      femaleButton.setTextColor(color(0, 0, 255));
      maleButton.setTextColor(color(0));
      sendCharacterSelection("female");
    }
  } else {
    JSONObject message = new JSONObject();

    float worldMouseX = mouseX + status.getFloat("cx") - width / 2;
    float worldMouseY = mouseY + status.getFloat("cy") - height / 2;

    message.setFloat("targetX", worldMouseX);
    message.setFloat("targetY", worldMouseY);

    sendMessageToServer(message);
  }
}

void sendMessageToServer(JSONObject message) {
  client.write(message.toString());
  client.write('\0');
}

void sendCharacterSelection(String characterType) {
  JSONObject message = new JSONObject();
  message.setString("characterType", characterType);
  sendMessageToServer(message);
}

void clientEvent(Client client) {
  String payload = client.readStringUntil('\0');

  if (payload != null) {
    synchronized (status) {
      status = parseJSONObject(payload.substring(0, payload.length() - 1));
    }
  }
}

class Button {
  String label;
  float x, y, w, h;
  color textColor = color(0);

  Button(String label, float x, float y, float w, float h) {
    this.label = label;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  void display() {
    fill(255);
    rect(x, y, w, h, 10);
    fill(textColor);
    textAlign(CENTER, CENTER);
    textSize(30);
    text(label, x + w / 2, y + h / 2);
    textSize(15);
  }

  boolean isMouseOver() {
    return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }

  void setTextColor(color newColor) {
    textColor = newColor;
  }
}
