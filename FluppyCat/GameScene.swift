//
//  GameScene.swift
//  FluppyCat
//
//  Created by Nguyen, Kim on 11/2/17.
//  Copyright © 2017 knguyen1. All rights reserved.
//
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game features
    var isGameStarted = Bool(false)
    var isDied = Bool(false)
    let coinSound = SKAction.playSoundFileNamed("CoinSound.mp3", waitForCompletion: false)
    
    // UI features
    var score = Int(0)
    var scoreLbl = SKLabelNode()
    var highscoreLbl = SKLabelNode()
    var tapToPlayLbl = SKLabelNode()
    var restartBtn = SKSpriteNode()
    var pauseBtn = SKSpriteNode()
    var logoImg = SKSpriteNode()
    var wallPair = SKNode()
    var moveAndRemove = SKAction()
    
    // Bird is the word
    let birdAtlas = SKTextureAtlas(named:"kitty")
    var birdSprites = Array<SKTexture>()
    var bird = SKSpriteNode()
    var repeatActionBird = SKAction()
    
    // MARK - Override methods
    override func didMove(to view: SKView) {
        createScene()
    }

    // @function touchesBegan
    //
    // Called whenever the user touches the screen.
    // 1 - Starts the game, inits bird's gravity, and creates the Pause btn
    // 2 - Animates a shrink of the logo
    // 3 - Runs the repeatActionBird, giving appearance of the bird flapping its wings
    // 4 - Creates & adds the pillars to the GameScene
    // 5 - Runs the spawn & delay functions SKActions forever
    // 6 - Set up the move & remove actions - controls the speed of the game
    // 7 - Apply the impulse on the bird as long as the game's started and the bird's not dead
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if (isGameStarted == false) {
            //1
            isGameStarted =  true
            bird.physicsBody?.affectedByGravity = true
            createPauseBtn()
            //2
            logoImg.run(SKAction.scale(to: 0.5, duration: 0.3), completion: {
                self.logoImg.removeFromParent()
            })
            tapToPlayLbl.removeFromParent()
            //3
            self.bird.run(repeatActionBird)
            
            //4
            let spawn = SKAction.run({
                () in
                self.wallPair = self.createWalls()
                self.addChild(self.wallPair)
            })
            //5
            // Wait for 1.5 seconds before the next pillars are generated
            let delay = SKAction.wait(forDuration: 1.5)
            let SpawnDelay = SKAction.sequence([spawn, delay])
            let spawnDelayForever = SKAction.repeatForever(SpawnDelay)
            self.run(spawnDelayForever)
            //6
            let gameSpeed = CGFloat(75);
            let durationFactor = CGFloat(0.008)
            let distance = CGFloat(self.frame.width + wallPair.frame.width)
            let movePillars = SKAction.moveBy(x: -distance - gameSpeed, y: 0, duration: TimeInterval(durationFactor * distance))
            let removePillars = SKAction.removeFromParent()
            moveAndRemove = SKAction.sequence([movePillars, removePillars])
            
            // Set velocity to 0 so it remains steady
            bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            // Applies an upward impulse
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 40))
        } else {
            //7
            if (isDied == false) {
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 40))
            }
        }
        
        for touch in touches {
            let location = touch.location(in: self)
            // If the game is over, and the user taps on the restartBtn
            if (isDied == true) {
                if (restartBtn.contains(location)) {
                    // We set the new high score if there is one
                    if UserDefaults.standard.object(forKey: "highestScore") != nil {
                        let hscore = UserDefaults.standard.integer(forKey: "highestScore")
                        if hscore < Int(scoreLbl.text!)!{
                            UserDefaults.standard.set(scoreLbl.text, forKey: "highestScore")
                        }
                    } else {
                        UserDefaults.standard.set(0, forKey: "highestScore")
                    }
                    restartScene()
                }
            }
            // If the game is NOT over, and the user taps on the pause button
            else {
                if (pauseBtn.contains(location)) {
                    // Pause the game, or resume
                    if (self.isPaused == false) {
                        self.isPaused = true
                        pauseBtn.texture = SKTexture(imageNamed: FCConstants.Images.play)
                    } else {
                        self.isPaused = false
                        pauseBtn.texture = SKTexture(imageNamed: FCConstants.Images.pause)
                    }
                }
            }
        }
    }
    
    // @function update
    // Called before each frame is rendered (e.g., 20fps game, calls update() 20 times a second)
    override func update(_ currentTime: TimeInterval) {
        // Controls the speed the background moves to the left
        let backgroundSpeed: CGFloat = 2;
        
        // If the game is started, and it's not over
        if (isGameStarted == true) {
            if (isDied == false) {
                enumerateChildNodes(withName: "background", using: ({
                    (node, error) in
                    let bg = node as! SKSpriteNode
                    // move the background at the rate of the gameSpeed
                    bg.position = CGPoint(x: bg.position.x - backgroundSpeed, y: bg.position.y)
                    if bg.position.x <= -bg.size.width {
                        bg.position = CGPoint(x:bg.position.x + bg.size.width * backgroundSpeed, y:bg.position.y)
                    }
                }))
            }
        }
    }
    
    
    // MARK: GameScene methods
    
    // @function createScene
    // categoryBitMask - a mask that defines which categories this physics body belongs to
    // collisionBitMask - prevents objects from intersecting (by default, will collide with everything)
    // contactTestBitMask - used to know if two objects touch each other so we can change the gameplay (by default, will not inform collisions at all)
    func createScene(){
        // Creates a physics body around the entire screen using edgeLoopFrom initializer
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        // Then, uses the CollisionBitMask constants to set the physics bodies
        // Note the .birdCategory bit masks, because we want to detect collisions & contacts with the bird
        self.physicsBody?.categoryBitMask = CollisionBitMask.groundCategory
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = CollisionBitMask.birdCategory
        self.physicsBody?.isDynamic = false
        // Setting affectedByGravity to false will prevent the player from falling off the screen
        self.physicsBody?.affectedByGravity = false
        
        self.physicsWorld.contactDelegate = self
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        
        // Create two instances of background node & place them side by side
        // This gives the appearance of a seamless moving background
        for i in 0..<2
        {
            let background = SKSpriteNode(imageNamed: FCConstants.Images.bg)
            background.anchorPoint = CGPoint.init(x: 0, y: 0)
            background.position = CGPoint(x:CGFloat(i) * self.frame.width, y:0)
            background.name = "background"
            background.size = (self.view?.bounds.size)!
            self.addChild(background)
        }
        
        // Set up the bird sprites for animation
        birdSprites.append(birdAtlas.textureNamed("kitty1"))
        birdSprites.append(birdAtlas.textureNamed("kitty2"))
        birdSprites.append(birdAtlas.textureNamed("kitty3"))
//        birdSprites.append(birdAtlas.textureNamed("kitty4"))
        
        // Initialize the bird, then add it to the GameScene
        self.bird = createBird()
        self.addChild(bird)
        
        // Initialize an SKAction object which takes all the birdSprites and loops them for 0.01 sec each, forever
        let animateBird = SKAction.animate(with: self.birdSprites, timePerFrame: 0.1)
        self.repeatActionBird = SKAction.repeatForever(animateBird)
        
        // Add other UI sprites to the GameScene
        scoreLbl = createScoreLabel()
        self.addChild(scoreLbl)
        highscoreLbl = createHighscoreLabel()
        self.addChild(highscoreLbl)
        createLogo()
        tapToPlayLbl = createTapToPlayLabel()
        self.addChild(tapToPlayLbl)
    }
    
    // @function didBegin
    //
    // Checks for contact between two physics bodies
    // TODO: Figure out a cleaner way to check both bodies.. pretty messy atm
    func didBegin(_ contact: SKPhysicsContact) {
        // The "contact" param contains a reference to both the bodies that colllide
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if (isDied == false) {
            // If the bird collides with any pillar or the ground
            if (firstBody.categoryBitMask == CollisionBitMask.birdCategory && secondBody.categoryBitMask == CollisionBitMask.pillarCategory)
                || (firstBody.categoryBitMask == CollisionBitMask.pillarCategory && secondBody.categoryBitMask == CollisionBitMask.birdCategory) {
                // Stop the game
                enumerateChildNodes(withName: "wallPair", using: ({
                    (node, error) in
                    node.speed = 0
                    self.removeAllActions()
                }))
                isDied = true
                createRestartBtn()
                pauseBtn.removeFromParent()
                self.bird.removeAllActions()
                
                // let the bird fall through the pillars/ground
                firstBody.collisionBitMask = 0;
                secondBody.collisionBitMask = 0;
                
                // spin the bird on death lol
                bird.physicsBody?.applyImpulse(CGVector(dx: -5, dy: 100))
                let scale = SKAction.scale(by: 3, duration: 3.0)
                let rotate = SKAction.rotate(byAngle: CGFloat(-1080), duration: 3.0)
                let group = SKAction.group([scale, rotate])
                self.bird.run(group, completion: {
                    self.bird.removeFromParent()
                })
            }
                // If the bird collides with a flower
            else if (firstBody.categoryBitMask == CollisionBitMask.birdCategory && secondBody.categoryBitMask == CollisionBitMask.flowerCategory) {
                
                // increment the score, remove the flower node
                run(coinSound)
                score += 1
                scoreLbl.text = "\(score)"
                secondBody.node?.removeFromParent()
            }
                // If the bird collides with a flower (duplicate code of above)
            else if (firstBody.categoryBitMask == CollisionBitMask.flowerCategory && secondBody.categoryBitMask == CollisionBitMask.birdCategory) {
                
                // increment the score, remove the flower node
                run(coinSound)
                score += 1
                scoreLbl.text = "\(score)"
                firstBody.node?.removeFromParent()
            }
        }
    }
    
    // @function restartScene
    //
    // Called when we want to restart the GameScene
    // Removes all nodes and stops all actions
    func restartScene(){
        self.removeAllChildren()
        self.removeAllActions()
        isDied = false
        isGameStarted = false
        score = 0
        createScene()
    }
    
    
}
