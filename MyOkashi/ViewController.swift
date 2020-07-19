//
//  ViewController.swift
//  MyOkashi
//
//  Created by Sakurako Shimbori on 2020/07/18.
//  Copyright © 2020 Taisei Hikawa. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController,UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate,SFSafariViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //Search Barのdelegate通知先を設定
        searchText.delegate = self
        //入力のヒントとなる、プレースホルダーを設定
        searchText.placeholder = "お菓子の名前を入力してください"
        //Table ViewのdataSourceを設定
        tableView.dataSource = self
        //Table Viewのdelegate設定
        tableView.delegate = self
    }
    
    
    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    //お菓子のリスト(タプル配列)
    var okashiList : [(name:String , maker:String , link:URL , image:URL)] = []
    //検索ボタンをクリック(タップ)時
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //キーボードを閉じる
        view.endEditing(true)
        
        if let searchWord = searchBar.text{
            //デバッグエリアに出力
            print(searchWord)
            //入力されていたら、お菓子を検索
            searchOkashi(keyword: searchWord)
            
        }
    }
    
    //JSONのitem内のデータ構造
    struct ItemJson : Codable{
        //お菓子の名称
        let name:String?
        //メーカー
        let maker : String?
        //掲載URL
        let url : URL?
        //画像URL
        let image : URL?
    }
    //JSONのデータ構造
    struct ResultJson: Codable{
        //複数要素
        let item:[ItemJson]?
    }
    
    //検索ボタンをクリック時
    func searchOkashi(keyword: String){
        //お菓子の検索キーワードをURLエンコードする
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        //リクエストURLの組み立て
        guard let req_url = URL(string: "https://sysbird.jp/toriko/api/?apikey=guest&format=json&keyword=\(keyword_encode)&max=10&order=r") else {
            return
        }
        print(req_url)
        
        //リクエストに必要な情報を生成
        let req = URLRequest(url: req_url)
        //データ転送を管理するためのセッションを生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        //リクエストをタスクとして登録
        let task = session.dataTask(with: req,completionHandler: {
            (data , response , error) in
            //セッションを終了
            session.finishTasksAndInvalidate()
            //do try carch エラーハンドリング
            do{
                //JSONDecoderのインスタンス取得
                let decoder = JSONDecoder()
                //受取ったJSONデータをパースして格納
                let json = try decoder.decode(ResultJson.self, from: data!)
                //お菓子の情報が取得できているか確認
                if let items = json.item{
                    //お菓子のリストを初期化
                    self.okashiList.removeAll()
                    //取得しているお菓子の数だけ処理
                    for item in items {
                        if let name = item.name , let maker = item.maker , let link = item.url , let image = item.image{
                            //１つのお菓子をタプルでまとめて管理
                            let okashi = (name,maker,link,image)
                            //お菓子の配列へ追加
                            self.okashiList.append(okashi)
                        }
                    }
                    //TableViewを更新する
                    self.tableView.reloadData()
                    if let okashidbg = self.okashiList.first{
                        print("--------------")
                        print("okashiList[0] = \(okashidbg)")
                    }
                }
            }catch{
                //エラー処理
                print("エラーが出ました")
            }
        })
        task.resume()
    }
    //Cellの総数を返すdatasourceメソッド。必ず記述する必要があります
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       //お菓子リストの総数
        return okashiList.count
    }
    
    //Cellに値を設定するdetaSourceメソッド。必ず記述する必要があります。
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //今回行う、cellオブジェクト(1行)を取得する
        let cell = tableView.dequeueReusableCell(withIdentifier: "okashiCell", for: indexPath)
        //お菓子のタイトル設定
        cell.textLabel?.text = okashiList[indexPath.row].name
        //お菓子の画像を取得
        if let imageData = try? Data(contentsOf: okashiList[indexPath.row].image){
            //正常に取得できた場合は、UIImageで画像オブジェクトを生成して、Cellにお菓子画像を設定
            cell.imageView?.image = UIImage(data: imageData)
        }
        return cell
    }
    
    //Cellが選択された際に呼び出されるdelegateメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //ハイライト解除
        tableView.deselectRow(at: indexPath, animated: true)
        //SFSafariViewを開く
        let safariViewController = SFSafariViewController(url: okashiList[indexPath.row].link)
        //delegateの通知先を自分自身
        safariViewController.delegate = self
        //SafariViewが開かれる
        present(safariViewController, animated: true, completion: nil)
    }
    
    //Safariが閉じられた時に呼ばれるdelegateメソッド
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        //SafariViewを閉じる
        dismiss(animated: true, completion: nil)
    }
}

