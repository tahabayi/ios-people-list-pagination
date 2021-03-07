//
//  ViewController.swift
//  PeopleList
//
//  Created by Taha Metin Bayi on 7.03.2021.
//

import UIKit

class ViewController: UIViewController {

    private var people: [Person] = []
    private var idSet: Set<Int> = Set()
    
    private lazy var peopleTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "personCell")
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self,
                                            action: #selector(handleRefresh),
                                            for: .valueChanged)
        return tableView
    }()
    
    private lazy var noOneHereLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No one here :)"
        label.isHidden = true
        return label
    }()
    
    override func loadView() {
        super.loadView()
        
        view.addSubview(peopleTableView)
        view.addSubview(noOneHereLabel)
        
        NSLayoutConstraint.activate([
            peopleTableView.topAnchor.constraint(equalTo: view.topAnchor),
            peopleTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            peopleTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            peopleTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            
            noOneHereLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noOneHereLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchData()
    }
    
    private func fetchData(refresh: Bool = false) {
        FetchingPeopleService.shared.fetchPeople(onSuccess: handle(peopleData:refresh:),
                                                 onError: handle(error:refresh:),
                                                 refresh: refresh)
    }
    
    private func handle(peopleData: [Person], refresh: Bool) {
        if refresh {
            people.removeAll()
            idSet.removeAll()
        }
        for person in peopleData {
            if !idSet.contains(person.id) {
                people.append(person)
                idSet.insert(person.id)
            }
        }
        setNoOneHereView(visible: people.isEmpty)
        DispatchQueue.main.async {
            self.peopleTableView.refreshControl?.endRefreshing()
            self.peopleTableView.reloadData()
        }
    }
    
    private func handle(error: FetchError, refresh: Bool) {
        let message = error.errorDescription
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { _ in
            alert.dismiss(animated: true) { [weak self] in
                self?.fetchData(refresh: refresh)
            }
        })
        alert.addAction(retryAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func setNoOneHereView(visible: Bool) {
        peopleTableView.separatorStyle = visible ? .none : .singleLine
        noOneHereLabel.isHidden = !visible
    }
    
    @objc private func handleRefresh() {
        fetchData(refresh: true)
    }

}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "personCell", for: indexPath)
        let person = people[indexPath.row]
        cell.textLabel?.text = "\(person.fullName) (\(person.id))"
        return cell
    }
    
}

extension ViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if indexPath.row >= people.count {
                fetchData()
                return
            }
        }
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == people.count {
            fetchData()
        }
    }
    
}
