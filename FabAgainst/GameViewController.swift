//
//  GameViewController.swift
//  FabAgainst
//
//  Created by Mickey Barboi on 9/29/15.
//  Copyright © 2015 paradrop. All rights reserved.
//

/*
Musings:
Table allows touches and interactivity based on the current chooser and the phase

Collection always shows the players
The chooser is always highlighted
The winner blinks when selected
*/


import UIKit
import Riffle
import RMSwipeTableViewCell
import M13ProgressSuite

// Testing ui code
let MAX = CGFloat(70.0)


class GameViewController: UIViewController {
    
    @IBOutlet weak var viewProgress: TickingView!
    @IBOutlet weak var labelActiveCard: UILabel!
    @IBOutlet weak var tableCard: UITableView!
    @IBOutlet weak var collectionPlayers: UICollectionView!
    @IBOutlet weak var buttonBack: UIButton!
    
    var tableDelegate: CardTableDelegate?
    var collectionDelegate: PlayerCollectionDelegate?
    
    var session: RiffleSession?
    var state: String = "Empty"
    var players: [Player] = []
    var currentPlayer = Player()
    var room: String = ""
    
    
    override func viewDidLoad() {
        tableDelegate = CardTableDelegate(tableview: tableCard, parent: self)
        collectionDelegate = PlayerCollectionDelegate(collectionview: collectionPlayers, parent: self)
        
        buttonBack.imageView?.contentMode = .ScaleAspectFit
        collectionDelegate!.playersChanged(players)
        
        if state == "Picking" {
            tableDelegate!.setTableCards(currentPlayer.hand)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        session!.subscribe(room + "/round/picking", picking)
        session!.subscribe(room + "/round/choosing", choosing)
        session!.subscribe(room + "/round/scoring", scoring)
        session!.subscribe(room + "/play/picked", picked)
        session!.subscribe(room + "/joined", newPlayer)
        session!.subscribe(room + "/left", playerLeft)
        session!.register(session!.domain + "/draw", draw)
    }
    
    override func viewWillDisappear(animated: Bool) {
        // Have to unsub or unregister!
        // TODO: overload for version that doesn't take a handler block
        
        // Temporary
        currentPlayer.hand = []
        session!.call(room + "/leave", currentPlayer, handler: nil)
        
        session!.unsubscribe(room + "/round/picking")
        session!.unsubscribe(room + "/round/choosing")
        session!.unsubscribe(room + "/round/scoring")
        session!.unsubscribe(room + "/play/picked")
        session!.unsubscribe(room + "/joined")
        session!.unsubscribe(room + "/left")
        
        session!.unregister(session!.domain + "/draw")
    }
    
    @IBAction func leave(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func picking(player: Player, card: Card, time: Double) {
        state = "Picking"
        labelActiveCard.text = card.text
        _ = players.map { $0.chooser = $0 == player }
        tableDelegate!.setTableCards(player.domain == session!.domain ? [] : currentPlayer.hand)
        viewProgress.countdown(time)
    }
    
    func choosing(choices: [Card], time: Double) {
        state = "Choosing"
        tableDelegate?.setTableCards(choices)
        tableCard.reloadData()
        viewProgress.countdown(time)
    }
    
    func scoring(player: Player, time: Double) {
        state = "Scoring"
        player.score += 1
        flashCell(player, model: players, collection: collectionPlayers)
        collectionPlayers.reloadData()
        viewProgress.countdown(time)
    }
    
    func newPlayer(player: Player) {
        players.append(player)
        collectionPlayers.reloadData()
    }
    
    func playerLeft(player: Player) {
        players.removeObject(player)
        collectionPlayers.reloadData()
    }
    
    func picked(player: Player) {
        
    }
    
    func draw(cards: [Card]) {
        currentPlayer.hand += cards
    }
    
    func playerSwiped(card: Card) {
        if state == "Picking" && !currentPlayer.chooser {
            session!.call(room + "/play/pick", currentPlayer, card, handler: nil)
            tableDelegate!.removeCellsExcept([card])
        } else if state == "Choosing" && currentPlayer.chooser {
            session!.publish(room + "/play/choose", card)
            tableDelegate!.removeCellsExcept([card])
        } else {
            print("Pick occured outside a valid round! OurChoice: \(currentPlayer.chooser), state: \(state)")
        }
    }
}