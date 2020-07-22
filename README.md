# metal-demo
[Metal](https://developer.apple.com/metal/)の練習用プロジェクトを管理するためのレポジトリです。
ルートディレクトリ直下の各ディレクトリ内に独立したプロジェクトが格納されています。

# Contents
以下、各ディレクトリ内のプロジェクトの説明です。

| dir name | description |
| -------- | ----------- |
| RotateImage+Offscreen+Save/ | 画像表示、画像回転、オフスクリーンレンダリング、レンダリングした画像を保存を行います。|
| Filtering/ | 画像のフィルタリングを行います。 |

# Challenges
- 画像をMetalでレンダリングする
- vertex/fragment shaderで画像を回転させる
- compute shaderで画像を回転させる
- オフスクリーンレンダリングする
- レンダリングした画像を保存する
- 画像にフィルターをかける
- MetalでDFTを実装する
  