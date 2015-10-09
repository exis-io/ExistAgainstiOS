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
let DEB = false

class GameViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RMSwipeTableViewCellDelegate {
    
    @IBOutlet weak var viewProgress: TickingView!
    @IBOutlet weak var labelActiveCard: UILabel!
    @IBOutlet weak var tableCard: UITableView!
    @IBOutlet weak var collectionPlayers: UICollectionView!
    @IBOutlet weak var buttonBack: UIButton!
    
    var session: RiffleSession?
    var state: State = .Empty
    var players: [Player] = []
    var hand: [Card] = []
    var room: String = ""
    
    // The cards currently in play
    var table: [Card] = []
    
    //Questionable or temporary
    var chooser = ""
    
    override func viewDidLoad() {
        tableCard.estimatedRowHeight = 100
        tableCard.rowHeight = UITableViewAutomaticDimension
        buttonBack.imageView?.contentMode = .ScaleAspectFit
        
        if DEB {
            state = .Picking
            
            let c = Card()
            c.text = "Test 1"
            c.id = 1
            hand.append(c)
            
            let d = Card()
            d.text = "Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1Test 1"
            d.id = 1
            hand.append(d)
        }
        
        if state == .Picking {
            table = hand
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if !DEB {
            session!.subscribe(room + "/round/picking", picking)
            session!.subscribe(room + "/round/choosing", choosing)
            session!.subscribe(room + "/round/scoring", scoring)

            //session!.subscribe(room + "/play/picked", picked)
            
            session!.register(session!.domain + "/draw", draw)
            session!.subscribe(room + "/joined", newPlayer)
            session!.subscribe(room + "/left", playerLeft)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        // Have to unsub or unregister!
        // TODO: overload for version that doesn't take a handler block
        if !DEB {
            session!.call(room + "/leave", session!.domain, handler: nil)
        }
    }

    
    // MARK: Incoming state 
    func picking(domain: String, card: Card, time: Double) {
        state = .Picking
        labelActiveCard.text = card.text
        chooser = domain
        
        // are we choosing this round?
        print("Choosen domain: \(domain), our domain: \(session!.domain)")
        table = chooser == session!.domain ? [] : hand
        
        tableCard.reloadData()
        viewProgress.countdown(time)
    }
    
    func choosing(choices: [[String: AnyObject]], time: Double) {
        state = .Choosing
        print("Choosing: \(table)")
        table = choices.map { Card.fromJson($0) }
        tableCard.reloadData()
        viewProgress.countdown(time)
    }
    
    func scoring(player: String, time: Double) {
        state = .Scoring
        
        if player == "" {
            // chooser didn't pick. No winner. Strictly speaking, this shouldn't be possible
        } else {
            // Flash the winner, remove the other cards off the screen, incrememnt their score on the bottom pane
            print("Player \(player) won!")
            var winners = players.filter { $0.domain == player }
            
            if winners.count == 0 {
                print("Uh oh. Nothing found.")
            } else {
                let winner = winners[0]
                winner.score += 1
            }
            
            // Flash the cell
            //flashCell(player, model: players, collection: collectionPlayers)
            collectionPlayers.reloadData()
        }
        
        viewProgress.countdown(time)
    }
    
    func newPlayer(player: String) {
        let p = Player()
        p.domain = player
        players.append(p)
        collectionPlayers.reloadData()
    }
    
    func playerLeft(player: String) {
        let p = players.filter({$0.domain == player})[0]
        players.removeObject(p)
        collectionPlayers.reloadData()
    }
    
    func picked(player: String) {
        // Show that the player picked. Defer for now
        if state == .Picking && !(chooser == session!.domain) {
            let c = Card()
            c.text = ""
            c.id = 1
            table.append(c)
        }
    }
    
    func draw(cardJson: [String: AnyObject]) {
        hand.append(Card.fromJson(cardJson))
    }
    
    
    //MARK: Table Delegate and Data Source
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("card") as! CardCell
        cell.labelTitle.text = table[indexPath.row].text
        
        // Style the cell
        cell.viewHolder.layer.cornerRadius = 6
        cell.viewHolder.layer.masksToBounds = true
        
        let backView = UIView(frame: cell.frame)
        backView.backgroundColor = UIColor.clearColor()
        cell.backgroundView = backView
        
        cell.backgroundColor = UIColor.clearColor()
        cell.backViewbackgroundColor = UIColor.clearColor()
        cell.contentView.backgroundColor = UIColor.clearColor()
        
        cell.delegate = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return table.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    //MARK: Collection Delegate and Data Source
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("player", forIndexPath: indexPath) as! PlayerCell
        let player = players[indexPath.row]
        
        cell.labelName.text = player.domain.stringByReplacingOccurrencesOfString("pd.demo.cardsagainst.", withString: "")
        cell.labelScore.text = "\(player.score)"
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return players.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 2, height: 100)
    }
    
    
    //MARK: Switping Delegate
    func swipeTableViewCell(swipeTableViewCell: RMSwipeTableViewCell!, didSwipeToPoint point: CGPoint, velocity: CGPoint) {
        let cell = swipeTableViewCell as! CardCell
        
        let MAX = CGFloat(70.0)
        
        let ourChoice = chooser == session!.domain
        let index = tableCard.indexPathForCell(cell)
        let card = table[index!.row]
        
        // right side selection
        if point.x >= MAX || point.x <= (-1 * MAX) {
            // reset the cell
            cell.resetContentView()
            cell.interruptPanGestureHandler = true
            
            // Dont really have to worry about out of turn selections-- the chooser should see a blank table
            // based on the construction of the table in the reload methods
            if state == .Picking && !ourChoice {
                session!.call(room + "/play/pick", session!.domain, card.id, handler: nil )
                removeCellsExcept([card])
            } else if state == .Choosing && ourChoice {
                session!.publish(room + "/play/choose", card.id)
                removeCellsExcept([card])
            } else {
                print("Pick occured outside a valid round! OurChoice: \(ourChoice), state: \(state)")
            }
        }
        
        // Left side selection. Defer for now, although this should represent a "rejection" when choosing
    }
    
    // MARK: Actions
    @IBAction func leave(sender: AnyObject) {
        // Called when the user wants to leave the room. Unregister/subscribe to all relevant bits
        
        if !DEB {
            session!.unsubscribe(room + "/round/picking")
            session!.unsubscribe(room + "/round/choosing")
            session!.unsubscribe(room + "/round/scoring")
            
            //session!.unsubscribe(room + "/play/picked")
            
            session!.unregister(session!.domain + "/draw")
            session!.unsubscribe(room + "/joined")
            session!.unsubscribe(room + "/left")
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //MARK: Utility
    func removeCellsExcept(keep: [Card]) {
        // removes all cards from the tableview and the table object except those passed
        
        var ret: [NSIndexPath] = []
        
        for i in 0...(table.count - 1) {
            if !keep.contains(table[i]) {
                ret.append(NSIndexPath(forRow: i, inSection: 0))
            }
        }
        
        table = keep
        tableCard.deleteRowsAtIndexPaths(ret, withRowAnimation: .Left)
    }
}