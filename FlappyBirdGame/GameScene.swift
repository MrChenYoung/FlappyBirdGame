//
//  GameScene.swift
//  FlappyBirdGame
//
//  Created by MrChen on 2019/4/5.
//  Copyright © 2019 MrChen. All rights reserved.
//

import SpriteKit
import GameplayKit

let birdCategory: UInt32 = 0x1 << 0

let pipeCategory: UInt32 = 0x1 << 1

let floorCategory: UInt32 = 0x1 << 2

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // 地面
    var floor1: SKSpriteNode!
    var floor2: SKSpriteNode!
    
    // 小鸟
    var bird: SKSpriteNode!
    
    // 游戏状态
    enum GameStatus {
        case idle    //初始化
        case running    //游戏运行中
        case over    //游戏结束
    }
    // 游戏状态变量(初始化状态)
    var gameStatus: GameStatus = .idle
    
    // 点击开始游戏提示
    lazy var startGameNode: SKSpriteNode = {
        let startGame = SKSpriteNode(imageNamed: "TapToPlay")
        startGame.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5 + 100)
        return startGame
    }()
    
    // 游戏结束提示文字
    lazy var gameOverLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "GAME OVER"
        label.zPosition = 200
        return label
    }()
    
    // 小鸟飞了多远(表示用户得分)
    lazy var metersLabel: SKLabelNode = {
        let label = SKLabelNode(text: "meters:0")
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .center
        return label
    }()
    
    // 飞行距离
    var meters = 0 {
        didSet  {
            metersLabel.text = "meters:\(meters)"
        }
    }
    
    override func didMove(to view: SKView) {
        // 场景内添加物体
        addNodes()
        
        // 设置场景内的物理体
        setPhysicsBody()
        
        // 初始化游戏
        shuffle()
    }
    
    // 在场景内添加需要的物体
    func addNodes() {
        // 设置场景的背景色
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        
        // 添加两段地面
        floor1 = SKSpriteNode(imageNamed: "floor")
        floor1.anchorPoint = CGPoint(x: 0, y: 0)
        floor1.position = CGPoint(x: 0, y: 0)
        addChild(floor1)
        floor2 = SKSpriteNode(imageNamed: "floor")
        floor2.anchorPoint = CGPoint(x: 0, y: 0)
        floor2.position = CGPoint(x: floor1.size.width, y: 0)
        addChild(floor2)
        
        // 添加小鸟
        bird = SKSpriteNode(imageNamed: "player1")
        addChild(bird)
        
        // 添加计分提示文字
        metersLabel.position = CGPoint(x: 0, y: self.size.height)
        metersLabel.horizontalAlignmentMode = .left
        metersLabel.zPosition = 100
        addChild(metersLabel)
        
        //添加gameOverLabel到场景里
        addChild(gameOverLabel)
    }
    
    // 设置场景内的物理体
    func setPhysicsBody() {
        // 给场景添加一个物理体，这个物理体就是一条沿着场景四周的边，限制了游戏范围，其他物理体就不会跑出这个场景
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        // 物理世界的碰撞检测代理为场景自己，这样如果这个物理世界里面有两个可以碰撞接触的物理体碰到一起了就会通知他的代理
        self.physicsWorld.contactDelegate = self
        
        //配置地面1的物理体
        floor1.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor1.size.width, height: floor1.size.height))
        floor1.physicsBody?.categoryBitMask = floorCategory
        //配置地面2的物理体
        floor2.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor2.size.width, height: floor2.size.height))
        floor2.physicsBody?.categoryBitMask = floorCategory
        
        // 设置小鸟物理体
        bird.physicsBody = SKPhysicsBody(texture: bird.texture!, size: bird.size)
        //禁止旋转
        bird.physicsBody?.allowsRotation = false
        //设置小鸟物理体标示
        bird.physicsBody?.categoryBitMask = birdCategory
        //设置可以小鸟碰撞检测的物理体
        bird.physicsBody?.contactTestBitMask = floorCategory | pipeCategory
    }
    
    
    // 当两个物体碰撞的时候调用
    func didBegin(_ contact: SKPhysicsContact) {
        //先检查游戏状态是否在运行中，如果不在运行中则不做操作，直接return
        if gameStatus != .running { return }
        
        //为了方便我们判断碰撞的bodyA和bodyB的categoryBitMask哪个小，小的则将它保存到新建的变量bodyA里的，大的则保存到新建变量bodyB里
        var bodyA : SKPhysicsBody
        var bodyB : SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bodyA = contact.bodyA
            bodyB = contact.bodyB
        }else {
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }
        
        // 判断是不是小鸟和管子碰撞 如果是游戏结束
        if (bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == pipeCategory) ||
            (bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == floorCategory) {
            gameOver()
        }
    }
    
    // 系统方法 在画面每一帧刷新的时候就会调用一次
    override func update(_ currentTime: TimeInterval) {
        // 让场景动起来
        if gameStatus == .running {
            moveScene()
        }
        
        // 计算飞行距离
        if gameStatus == .running {
            meters += 1
        }
    }
    
    // 点击屏幕
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
        case .idle:
            // 初始化状态下点击屏幕开始游戏
            startGame()
        case .running:
            //如果在游戏进行中状态下，玩家点击屏幕则给小鸟一个向上的力
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))
        case .over:
            //如果在游戏结束状态下，玩家点击屏幕重新开始
            shuffle()
        }
    }
    
    // 初始化游戏
    func shuffle() {
        gameStatus = .idle
        
        // 初始化小鸟没有受到物理环境的影响
        bird.physicsBody?.isDynamic = false
        
        // 添加点击屏幕开始游戏提示
        addChild(startGameNode)
        
        // 清理上局游戏的内容
        clearScene()
    }
    
    // 游戏开始
    func startGame() {
        gameStatus = .running
        
        // 移除点击屏幕开始游戏提示
        startGameNode.removeFromParent()
        
        // 小鸟开始飞
        birdStartFly()
        
        // 随机添加管子
        startCreateRandomPipesAction()
        
        // 开始游戏以后小鸟受到物理环境的影响
        bird.physicsBody?.isDynamic = true
    }
    
    // 游戏结束
    func gameOver() {
        gameStatus = .over
        
        // 小鸟停止飞
        birdStopFly()
        
        // 停止创建管子
        stopCreateRandomPipesAction()
        
        //禁止用户点击屏幕
        isUserInteractionEnabled = false
        
        // 添加游戏结束提示
        addChild(gameOverLabel)
        gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        
        //让gameOverLabel通过一个动画action移动到屏幕中间
        gameOverLabel.run(SKAction.move(by: CGVector(dx:0, dy:-self.size.height * 0.5), duration: 0.5), completion: {
            //动画结束才重新允许用户点击屏幕
            self.isUserInteractionEnabled = true
        })
    }
    
    // 让地面和水管移动起来
    func moveScene() {
        // 每一帧让地板想屏幕左边移动1
        floor1.position = CGPoint(x: floor1.position.x - 1, y: floor1.position.y)
        floor2.position = CGPoint(x: floor2.position.x - 1, y: floor2.position.y)
        
        // 如果地板1完全移出了屏幕就把它放到地板2的前面
        if floor1.position.x < -floor1.size.width {
            floor1.position = CGPoint(x: floor2.position.x + floor2.size.width, y: floor1.position.y)
        }
        
        // 如果地板2完全移出了屏幕就把它放到地板1的前面
        if floor2.position.x < -floor2.size.width {
            floor2.position = CGPoint(x: floor1.position.x + floor1.size.width, y: floor2.position.y)
        }
        
        //循环检查场景的子节点，同时这个子节点的名字要为pipe
        for pipeNode in self.children where pipeNode.name == "pipe" {
            //因为我们要用到水管的size，但是SKNode没有size属性，所以我们要把它转成SKSpriteNode
            if let pipeSprite = pipeNode as? SKSpriteNode {
                //将水管左移1
                pipeSprite.position = CGPoint(x: pipeSprite.position.x - 1, y: pipeSprite.position.y)
                
                //检查水管是否完全超出屏幕左侧了，如果是则将它从场景里移除掉
                if pipeSprite.position.x < -pipeSprite.size.width * 0.5 {
                    pipeSprite.removeFromParent()
                }
            }
        }
    }
    
    // 小鸟开始移动
    func birdStartFly() {
        let flyAction = SKAction.animate(with: [SKTexture(imageNamed: "player1"),
                                                SKTexture(imageNamed: "player2"),
                                                SKTexture(imageNamed: "player3"),
                                                SKTexture(imageNamed: "player2")],
                                         timePerFrame: 0.15)
        bird.run(SKAction.repeatForever(flyAction), withKey: "fly")
    }
    
    // 小鸟停止飞
    func birdStopFly() {
        bird.removeAction(forKey: "fly")
    }
    
    // 添加水管道场景内 topSize: 上水管的大小  bottomSize: 下水管的大小
    func addPipes(topSize: CGSize, bottomSize: CGSize) {
        //创建上水管
        let topTexture = SKTexture(imageNamed: "topPipe")
        
        //利用上水管图片创建一个上水管纹理对象
        let topPipe = SKSpriteNode(texture: topTexture, size: topSize)
        
        //利用上水管纹理对象和传入的上水管大小参数创建一个上水管对象
        //给这个水管取个名字叫pipe
        topPipe.name = "pipe"
        
        //设置上水管的垂直位置为顶部贴着屏幕顶部，水平位置在屏幕右侧之外
        topPipe.position = CGPoint(x: self.size.width + topPipe.size.width * 0.5, y: self.size.height - topPipe.size.height * 0.5)
        
        //创建下水管，每一句方法都与上面创建上水管的相同意义
        let bottomTexture = SKTexture(imageNamed: "bottomPipe")
        let bottomPipe = SKSpriteNode(texture: bottomTexture, size: bottomSize)
        
        bottomPipe.name = "pipe"
        
        //设置下水管的垂直位置为底部贴着地面的顶部，水平位置在屏幕右侧之外
        bottomPipe.position = CGPoint(x: self.size.width + bottomPipe.size.width * 0.5, y: self.floor1.size.height + bottomPipe.size.height * 0.5)
        
        //配置上水管物理体
        topPipe.physicsBody = SKPhysicsBody(texture: topTexture, size: topSize)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        
        //配置下水管物理体
        bottomPipe.physicsBody = SKPhysicsBody(texture: bottomTexture, size: bottomSize)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory
        
        //将上下水管添加到场景里
        addChild(topPipe)
        addChild(bottomPipe)
    }
    
    // 添加随机管子
    func createRandomPipes() {
        //先计算地板顶部到屏幕顶部的总可用高度
        let height = self.size.height - self.floor1.size.height
        
        //计算上下管道中间的空档的随机高度，最小为空档高度为2.5倍的小鸟的高度，最大高度为3.5倍的小鸟高度
        let pipeGap = CGFloat(arc4random_uniform(UInt32(bird.size.height))) + bird.size.height * 8.5
        
        //管道宽度在60
        let pipeWidth = CGFloat(60.0)
        
        //随机计算顶部pipe的随机高度，这个高度肯定要小于(总的可用高度减去空档的高度)
        let topPipeHeight = CGFloat(arc4random_uniform(UInt32(height - pipeGap)))
        
        //总可用高度减去空档gap高度减去顶部水管topPipe高度剩下就为底部的bottomPipe高度
        let bottomPipeHeight = height - pipeGap - topPipeHeight
        
        //调用添加水管到场景方法
        addPipes(topSize: CGSize(width: pipeWidth, height: topPipeHeight), bottomSize: CGSize(width: pipeWidth, height: bottomPipeHeight))
    }
    
    // 循环创建管子
    func startCreateRandomPipesAction() {
        //创建一个等待的action,等待时间的平均值为3.5秒，变化范围为1秒
        let waitAct = SKAction.wait(forDuration: 8.0, withRange: 1.0)
        
        //创建一个产生随机水管的action，这个action实际上就是调用一下我们上面新添加的那个createRandomPipes()方法
        let generatePipeAct = SKAction.run {
            self.createRandomPipes()
        }
        
        //让场景开始重复循环执行"等待" -> "创建" -> "等待" -> "创建"。。。。。
        //并且给这个循环的动作设置了一个叫做"createPipe"的key来标识它
        run(SKAction.repeatForever(SKAction.sequence([waitAct, generatePipeAct])), withKey: "createPipe")
    }
    
    // 停止循环创建管子
    func stopCreateRandomPipesAction() {
        self.removeAction(forKey: "createPipe")
    }
    
    // 移除场景内所有的管子
    func removeAllPipesNode() {
        //循环检查场景的子节点，同时这个子节点的名字要为pipe
        for pipe in self.children where pipe.name == "pipe" {
            //将水管这个节点从场景里移除掉
            pipe.removeFromParent()
        }
    }
    
    // 清理上局游戏的内容
    func clearScene() {
        // 移除以前创建的所有水管
        removeAllPipesNode()
        
        // 设置鸟的初始位置在屏幕中间
        bird.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        
        // 得分清零
        meters = 0
        
        // 移除游戏结束提示
        gameOverLabel.removeFromParent()
    }
}
