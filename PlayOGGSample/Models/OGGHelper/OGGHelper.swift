//
//  OGGHelper.swift
//  PlayOGGSample
//
//  Created by cranoo on 2025/03/24.
//

import Foundation
import SwiftOGG
import OggDecoder

struct OGGHelper {
    private let fileManager = FileManager.default
    private let tmpDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ogg_tmp")
    private let convertedDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("converted")
    
    /// リモートのoggファイルをm4a形式に変換する非同期メソッド
    /// - Parameter sourceURL: リモートのoggファイルのURL
    /// - Returns: 変換後のm4aファイルのURL
    /// - Throws: 変換またはファイル操作に関連するエラー
    /// - warning: 音声コーデックは`Opus`である必要があります
    ///
    /// リモートURLからOGGファイルを取得し、それをm4a形式に変換して指定されたディレクトリに保存します。
    func convertOpusOGGtoM4A(sourceURL: URL) async throws -> URL {
        let fileName = "tmp-\(fileNameDate())"
        
        // OGGファイルをリモートから取得
        let oggFileData = try await fetchOGGData(from: sourceURL)
        
        // 一時ファイルとしてOGGファイルを保存
        let savedOGGFileURL = try saveTemporaryFile(oggFileData, fileName: "\(fileName).ogg")
        
        // 変換後のm4aファイルの保存先URL
        try ensureDirectoryExists(convertedDirectory)
        let saveM4AFileURL = convertedDirectory.appendingPathComponent("\(fileName).m4a")
        
        print("OGG File: \n\(savedOGGFileURL.absoluteString)")
        print("M4A File: \n\(saveM4AFileURL.absoluteString)")
        
        // oggファイルをm4aに変換
        try OGGConverter.convertOpusOGGToM4aFile(src: savedOGGFileURL, dest: saveM4AFileURL)
        
        return saveM4AFileURL
    }
    
    /// リモートのoggファイルをwav形式に変換する非同期メソッド
    /// - Parameter sourceURL: リモートのoggファイルのURL
    /// - Returns: 変換後のwavファイルのURL
    /// - Throws: 変換またはファイル操作に関連するエラー
    /// - warning: 音声コーデックは`Vorbis`である必要があります
    ///
    /// リモートURLからoggファイルを取得し、それをwav形式に変換して指定されたディレクトリに保存します。
    func convertVorbisOGGtoWAV(sourceURL: URL) async throws -> URL {
        let fileName = "tmp-\(fileNameDate())"
        
        // OGGファイルをリモートから取得
        let oggFileData = try await fetchOGGData(from: sourceURL)
        
        // 一時ファイルとしてOGGファイルを保存
        let savedOGGFileURL = try saveTemporaryFile(oggFileData, fileName: "\(fileName).ogg")
        
        let result = await OGGDecoder().decode(savedOGGFileURL)
        guard let result else { throw OGGHelperError.invalidOGGFile }
        
        try ensureDirectoryExists(convertedDirectory)
        
        let savedWAVFileURL = convertedDirectory.appendingPathComponent("\(fileName).wav")
        try fileManager.moveItem(at: result, to: savedWAVFileURL)
        
        return savedWAVFileURL
    }
    
    func cashClear() throws {
        try fileManager.removeItem(at: tmpDirectory)
    }
    
    func deleteConvertedFiles() throws {
        try fileManager.removeItem(at: convertedDirectory)
    }
}

private extension OGGHelper {
    /// リモートURLからoggファイルのデータを非同期で取得するメソッド
    ///
    /// - Parameter url: oggファイルのリモートURL
    /// - Returns: oggファイルのデータ
    /// - Throws: ネットワークエラーまたはデータ取得エラー
    func fetchOGGData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    /// oggファイルデータを一時ファイルとして保存するメソッド
    ///
    /// - Parameters:
    ///   - data: 保存するoggファイルのデータ
    ///   - fileName: 保存するファイル名
    /// - Returns: 保存したファイルのURL
    /// - Throws: ファイル操作エラー
    func saveTemporaryFile(_ data: Data, fileName: String) throws -> URL {
        try ensureDirectoryExists(tmpDirectory)
        let fileURL = tmpDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }
    
    /// 指定したディレクトリが存在しない場合は作成するメソッド
    ///
    /// - Parameter directory: 確認するディレクトリのURL
    /// - Throws: ディレクトリ作成エラー
    func ensureDirectoryExists(_ directory: URL) throws {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
    /// 現在の日付と時刻を元に一意なファイル名を生成するメソッド
    ///
    /// - Returns: 日付と時刻を反映した一意なファイル名
    func fileNameDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: Date())
    }
}

enum OGGHelperError: Error {
    case invalidOGGFile
}
