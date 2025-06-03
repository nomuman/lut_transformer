# プロジェクト固有のルールやベストプラクティスを定義します。
# Clineはこのファイルを読み込み、タスク遂行の参考にします。

# 必ず不明点は質問してください。

rules:
  # --- コーディングスタイル ---

  - id: simple-implementation
    description: 必ずシンプルな実装を心がけてください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
      - file_pattern: "test/**/*.dart"
    guideline: |
      - コードはシンプルで明確に理解できるようにしてください。
      - 複雑なロジックやネストが深いコードは避け、必要に応じて関数やクラスに分割してください。
      - コメントは必要最低限にし、コード自体が自己説明的になるよう心がけてください。
      - 不要なコードやデバッグ用のコードは削除してください。

  - id: avoid-commented-out-code
    description: TODO, FIXME, NOTE, 重要な説明コメント以外のコメントアウトされたコードを禁じます。
    applies_to:
      - file_pattern: "lib/**/*.dart"
    guideline: |
      コメントアウトされたコードは、コードベースのノイズとなり、可読性を低下させ、
      古い情報や不要なコードを放置する原因となります。
      TODO, FIXME, NOTE または設計上の重要な決定事項や一時的な無効化に関する説明コメント
      (例: `// TODO(nomuman): Implement feature X`, `// FIXME: Handle edge case Y`, `// NOTE: This is important`, `// IMPORTANT: Temporarily disabled due to Z`)
      以外のコメントアウトされたコードは削除してください。
      万が一つけてしまった場合も最後にコメントアウトされたコードを削除するようにしてください。
      バージョン管理システムを使用して、過去のコードを参照できます。
      `analysis_options.yaml`で適切なLintルール（もし存在すれば）を設定することを検討してください。

  - id: adhere-to-naming-conventions
    description: Dartの標準的な命名規則に従ってください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
      - file_pattern: "test/**/*.dart"
    guideline: |
      - ファイル名: `snake_case.dart` (例: `user_repository.dart`)
      - クラス名、型定義名、拡張名、enum名: `PascalCase` (例: `UserRepository`, `AuthStatus`)
      - メソッド名、関数名、変数名、パラメータ名: `camelCase` (例: `getUserById`, `isLoading`)
      - 定数名: `camelCase` (推奨) または `UPPER_SNAKE_CASE` (例: `defaultTimeout`, `MAX_RETRIES`)
      詳細は Effective Dart: Style を参照してください: https://dart.dev/effective-dart/style#identifiers

  - id: write-doc-comments-for-public-apis
    description: 公開クラス、メソッド、関数にはDocコメントを記述してください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
    guideline: |
      公開されているクラス、ミックスイン、メソッド、関数、トップレベル変数、定数などには、
      その目的、使い方、パラメータ、戻り値などを説明するDocコメント (`///`) を記述してください。
      これにより、コードの可読性と保守性が向上します。
      `dart doc` コマンドでドキュメントを生成できます。
      詳細は Effective Dart: Documentation を参照してください: https://dart.dev/effective-dart/documentation

  - id: enforce-lint-rules
    description: `analysis_options.yaml` で定義された Lint ルールに従ってください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
    guideline: |
      プロジェクトで定義されている Lint ルール (例: flutter_lints, lints) を遵守し、
      コードスタイルの一貫性を保ち、潜在的な問題を早期に検出してください。
      `dart analyze` コマンドで違反がないか確認できます。

  # --- アーキテクチャと設計 ---

  - id: adhere-to-clean-architecture
    description: プロジェクトはクリーンアーキテクチャに基づいています。各レイヤーの役割とファイル配置に従ってください。
    applies_to:
      - file_pattern: "lib/domain/**/*.dart"
      - file_pattern: "lib/data/**/*.dart"
      - file_pattern: "lib/presentation/**/*.dart"
    guideline: |
      - domain: ビジネスロジック、エンティティ、ユースケース、リポジトリインターフェースを配置します。フレームワークに依存しません。
      - data: リポジトリの実装、データソース、モデルを配置します。外部ライブラリやフレームワークへの依存を含みます。
      - presentation: UI、ウィジェット、プロバイダーを配置します。Flutter フレームワークに依存します。

  - id: use-freezed-for-entities-and-models
    description: エンティティおよびモデルクラスはFreezedを使用して定義してください。
    applies_to:
      - file_pattern: "lib/domain/entities/*.dart"
      - file_pattern: "lib/domain/models/*.dart" # Data層のモデルにも適用する場合は追加
    guideline: |
      Freezedを使用することで、イミュータブルなデータクラスを簡単に生成し、
      copyWithやunion型などの機能を利用できます。
      クラス定義には `@freezed` アノテーションを使用し、`part` ディレクティブで
      生成されるファイル (`.freezed.dart` および `.g.dart`) を指定してください。
      コード生成を実行するには `dart run build_runner build --delete-conflicting-outputs` を使用します。

  - id: optimize-widgets
    description: ウィジェットの再利用性とパフォーマンスを意識してください。
    applies_to:
      - file_pattern: "lib/presentation/widgets/**/*.dart"
      - file_pattern: "lib/presentation/features/**/*.dart"
    guideline: |
      - 大きなウィジェットは、意味のある単位で小さな再利用可能なウィジェットに分割してください。
      - 変更されないウィジェットやその一部には `const` キーワードを積極的に使用し、
        不要なリビルドを避けてパフォーマンスを向上させてください。
      - `ListView` や `GridView` では `.builder` コンストラクタを使用してください。

  - id: ui-widget-decomposition-and-commonization
    description: UIウィジェットの分割と共通化に関する指針
    applies_to:
      - file_pattern: "lib/presentation/**/*.dart"
    guideline: |
      - **責務の分離:** 1つのウィジェットが複数の責務を持つ場合、意味のある単位でプライベートウィジェットに分割してください。
      - **可読性の向上:** `build` メソッドが長くなりすぎた場合、論理的なセクションごとにプライベートウィジェットに切り出してください。
      - **再利用性:** 複数の場所で同じUIパターンやロジックが繰り返される場合、共通ウィジェット (`lib/presentation/widgets/` 配下) として抽象化することを検討してください。
      - **過度な分割の回避:** 分割は可読性や保守性を向上させる目的で行い、過度な細分化は避けてください。
      - **ファイル配置:** まずはファイル内プライベートウィジェットとして分割し、他のフィーチャーからの利用が見込まれる場合や、ファイルサイズが著しく増大した場合に別ファイル (`lib/presentation/widgets/` 配下) への切り出しを検討してください。
      - **命名規則:** プライベートウィジェットは `_WidgetName` のようにアンダースコアで始めてください。共通ウィジェットは `CommonWidgetName` や `SpecificPurposeWidgetName` のように命名してください。

  # --- 状態管理 (Riverpod) ---

  - id: use-riverpod-for-state-management
    description: 状態管理には Riverpod を使用してください。可能な場合は Riverpod Generator と family プロバイダーを活用してください。
    applies_to:
      - file_pattern: "lib/presentation/providers/**/*.dart"
      - file_pattern: "lib/presentation/**/*.dart" # Providerを使用する箇所にも適用
    guideline: |
      - プロバイダーの定義には `@riverpod` アノテーションを使用し、コード生成を活用してください。
      - パラメータを持つプロバイダーには `family` を使用してください。
      - 状態の変更は `Notifier` または `AsyncNotifier` を使用してカプセル化してください。
      - UIのビルドメソッド内や他のプロバイダーのビルドメソッド内では `ref.watch` を使用してリアクティブに状態を購読してください。
      - ボタンのコールバックなど、リアクティブな更新が不要な場合は `ref.read` を使用してください。
      - 不要になったプロバイダーの状態を自動的に破棄するために、可能な限り `autoDispose` を使用してください (`@riverpod` ではデフォルト)。
      - プロバイダーのライフサイクルを管理する必要がある場合は `keepAlive` や `dependencies` を適切に設定してください。

  # --- テスト ---

  - id: write-tests
    description: 主要なロジックやウィジェットに対してテストを記述してください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
      - file_pattern: "test/**/*.dart"
    guideline: |
      - Domain レイヤーのビジネスロジックにはユニットテストを記述してください。
      - Presentation レイヤーのウィジェットにはウィジェットテストを記述してください。
      - 重要なユーザーフローにはインテグレーションテストの導入を検討してください。
      テストはコードの品質を保証し、リファクタリングを容易にします。

  - id: dart-unit-testing-best-practices
    description: Dartのユニットテストを作成する際のベストプラクティス
    applies_to:
      - file_pattern: "test/**/*_test.dart"
    guideline: |
      - テストファイル名は `{テスト対象}_test.dart` の形式にしてください。
      - テストクラス（グループ）名は `{テスト対象}Test` の形式にしてください。
      - 各テストは明確な命名で、テスト内容が理解できる名前を付けてください
        (例: `adds_product_to_cart_successfully`, `applies_valid_discount_coupon`)。
      - テストは「準備(Arrange)」「実行(Act)」「検証(Assert)」の3ステップで構成してください。
      - 各ステップの区切りにはコメントを入れるか、空行で区切ってください。
      - モックが必要な場合は mockito または mocktail を使用してください。
      - 期待値と実際の値を比較する際は、expect(actual, matcher) の形式を使用してください。
      - 例外のテストには `expect(() => ..., throwsA(isA<ExpectedException>()))` を使用してください。
      - テストデータは、テストクラス内の private 定数として定義するか、テストヘルパーとして分離してください。
      - 共通のセットアップは `setUp()` メソッドで行い、クリーンアップは `tearDown()` メソッドで行ってください。
      - 関連するテストはグループ化してください (`group()` を使用)。

  - id: unit-test-coverage-requirements
    description: ユニットテストのカバレッジ要件
    applies_to:
      - file_pattern: "test/**/*_test.dart"
    guideline: |
      - ドメイン層のロジックは 90% 以上のコードカバレッジを目指してください。
      - 特に以下の部分は必ずテストしてください：
        * 全てのパブリックメソッド
        * 重要な条件分岐
        * 例外ケースと境界値
        * ビジネスロジックが含まれる計算処理
      - テストカバレッジは `flutter test --coverage` で計測し、
        lcov レポートでカバレッジを可視化してください。
      - カバレッジが低い場合は、優先度の高い部分から順にテストを追加してください。

  - id: domain-layer-testing-focus
    description: ドメイン層のテスト重点ポイント
    applies_to:
      - file_pattern: "test/domain/**/*_test.dart"
    guideline: |
      - エンティティとバリューオブジェクトのバリデーションロジック
      - サービスクラスのビジネスルール
      - 計算ロジック（合計金額、税計算、割引適用など）
      - エッジケース（空のカート、無効な入力値、境界値など）
      - 状態変化の検証（アイテム追加前後の状態など）
      - データ整合性（合計金額と個別アイテム金額の整合性など）
      - インターフェースの契約遵守（リポジトリインターフェースの実装など）

  # --- エラーハンドリング ---

  - id: use-functionresult-for-api-responses
    description: Firebase FunctionsなどのAPI呼び出しの戻り値にはFunctionResultを使用してください。
    applies_to:
      - file_pattern: "lib/data/repositories/*_repository.dart"
    guideline: |
      API呼び出しの結果は、成功またはエラーのいずれかになります。
      FunctionResult<T> クラスを使用することで、成功時のデータ (T) と
      エラー時のCallableErrorsを型安全に扱うことができます。
      エラーハンドリングにはFunctionResultのisSuccess/isErrorゲッターやwhenメソッドを活用してください。
      (注記: プロジェクトの状況に応じて、`package:multiple_result` や `package:dartz` の `Either` のような、より標準的なResult型パターンへの移行も将来的に検討する価値があります。)

  - id: consistent-error-handling
    description: アプリケーション全体で一貫したエラーハンドリングを行ってください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
    guideline: |
      APIエラー (`FunctionResult`) 以外にも、予期せぬ例外やバリデーションエラーなどを
      適切にハンドリングしてください。ユーザーへのフィードバック方法 (例: SnackBar, Dialog) や
      エラーロギングの方針を統一することを推奨します。

  - id: comprehensive-exception-handling
    description: アプリケーション全体で階層的な例外処理アプローチを採用してください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
    guideline: |
      - グローバルレベル: main.dartにFlutterError.onErrorとrunZonedGuardedを実装し、未捕捉の例外を処理してください。
      - データソース/リポジトリレベル: 技術的な例外をキャッチし、意味のあるドメイン例外に変換してください。
      - ビジネスロジックレベル: ドメイン固有の例外処理を行い、複合操作のトランザクション管理を行ってください。
      - UIレベル: ユーザーへのエラー表示、リトライロジック、ユーザーエクスペリエンスの管理を行ってください。
      - Result型パターン: リポジトリやユースケースの戻り値にはResult<T>型を使用し、成功・失敗を型安全に処理してください。
      - カスタム例外クラス: アプリケーション固有の例外階層を定義し、例外の種類によって適切な処理を行ってください。

  - id: implement-global-error-handler
    description: アプリのエントリーポイントにグローバルエラーハンドラを実装してください。
    applies_to:
      - file_pattern: "lib/main.dart"
    guideline: |
      FlutterError.onErrorとrunZonedGuardedを使用して、フレームワーク内外の全ての未捕捉例外を処理し、
      ログ記録やクラッシュ分析サービス（FirebaseCrashlyticsなど）への送信を行ってください。
      本番環境では例外の詳細をユーザーに表示せず、適切なエラー表示とフォールバックメカニズムを提供してください。

  # --- Firebase 関連 ---

  - id: firebase-storage-path-structure
    description: Firebase Storage のファイルパス構造に関するルールです。
    applies_to:
      - file_pattern: "lib/data/datasources/remote/*_data_source.dart" # ストレージ操作を行う可能性のあるファイル
      - file_pattern: "lib/data/repositories/*_repository.dart" # ストレージ操作を行う可能性のあるファイル
    guideline: |
      - ユーザー関連ファイル: `users/{userId}/...`
      - テープコンテンツ: `tapes/{tapeId}/contents/{contentId}/...`
      - ハイライト動画/サムネイル: `tapes/{tapeId}/highlights/{monthly|yearly}/{yyyy-MM|yyyy}/...`
      - サムネイルサイズ: `.../thumbnails/{size}x{size}` の形式を使用してください。

  - id: secure-sensitive-information
    description: APIキーなどの機密情報をコードに直接埋め込まないでください。
    applies_to:
      - file_pattern: "lib/**/*.dart"
    guideline: |
      APIキー、シークレットキー、その他の機密情報は、ソースコードに直接記述せず、
      環境変数や `.env` ファイル、セキュアな設定管理方法 (例: flutter_secure_storage) を
      使用して管理してください。Firebase関連の設定ファイル (`google-services.json`, `GoogleService-Info.plist`) は
      バージョン管理システムに含めないように注意してください (.gitignoreで管理)。

  # --- その他 ---

  - id: run-build-runner-after-code-generation-changes
    description: FreezedやRiverpodなどのコード生成に関連するファイルを変更した後は、ビルドランナーを実行してください。
    applies_to:
      - file_pattern: "lib/**/*.dart" # 広範囲に適用
    guideline: |
      Freezed (.freezed.dart), json_serializable (.g.dart), Riverpod (.g.dart)
      などのコード生成が必要なファイルを変更または新規作成した場合は、
      以下のコマンドを実行して必要なコードを生成してください。
      `dart run build_runner build --delete-conflicting-outputs`
      これにより、コンパイルエラーを防ぎ、生成されたコードを利用できるようになります。

  - id: package-usage-guidelines
    description: 主要なパッケージの使用に関する推奨事項です。
    applies_to:
      - file_pattern: "lib/**/*.dart"
    guideline: |
      - HTTP 通信には dio を使用してください。
      - 宣言的なルーティングには go_router を使用してください。
      - イミュータブルなデータクラスには freezed を、JSON シリアライゼーションには json_serializable を使用してください。