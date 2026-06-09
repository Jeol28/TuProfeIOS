import Foundation

// MARK: - Cambia aquí: true = Firestore | false = API REST (Express/PostgreSQL)

enum DataSourceConfig {
    static let useFirestore = true
}

// MARK: - Factories (equivalente al DataModule de Android con Hilt)

func makeReviewDataSource() -> any ReviewDataSource {
    DataSourceConfig.useFirestore ? ReviewFirestoreDataSource() : ReviewAPIDataSource()
}

func makeUserDataSource() -> any UserDataSource {
    DataSourceConfig.useFirestore ? UserFirestoreDataSource() : UserAPIDataSource()
}

func makeProfessorDataSource() -> any ProfessorDataSource {
    DataSourceConfig.useFirestore ? ProfessorFirestoreDataSource() : ProfessorAPIDataSource()
}

func makeCommentDataSource() -> any CommentDataSource {
    DataSourceConfig.useFirestore ? CommentFirestoreDataSource() : CommentAPIDataSource()
}
