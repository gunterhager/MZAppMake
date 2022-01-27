import Foundation
import ArgumentParser

struct MZAppMake: ParsableCommand {
	static let configuration = CommandConfiguration(abstract: "Creates apps for the Sharp MZ-800 from binary files. It can create MZT tape files or WAV audio files.")

	@Option(name: [.customLong("input")], help: "Input: binary file or tape file.")
	var inputFile: String

	@Flag(name: [.customLong("input-as-tape")], help: "Interpret input file as tape file (MZF). (default: false)")
	var inputAsTape = false

	@Option(name: [.customLong("load")], help: "Load address, has no effect when input is tape.")
	var loadingAddress: String = "0x1500"

	@Option(name: [.customLong("start")], help: "Start address, has no effect when input is tape.")
	var startAddress: String = "0x1500"

	@Flag(name: [.customLong("audio")], help: "Create WAV file. (default: false)")
	var audio = false

	@Flag(name: [.customLong("fast")], help: "Using fast mode when creating WAV file. (default: false)")
	var fastAudio = false

	mutating func run() throws {
		let fileURL = URL(fileURLWithPath: inputFile)
		guard
			let name = fileURL.lastPathComponent.split(separator: ".").first
		else { throw MZError(message: "Input file name should have an extension separated by '.'.") }
		guard name.count < 17 else { throw MZError(message: "Input file name must 16 characters or less.") }

		let outputURL = fileURL
			.deletingLastPathComponent()
			.appendingPathComponent(name + ".mzf")
		let outputAudioURL = fileURL
			.deletingLastPathComponent()
			.appendingPathComponent(name + ".wav")

		// Load input file
		print("Loading file: \(fileURL)")
		let fileData = try Data(contentsOf: fileURL)

		// Setup recording
		let recording: Recording
		if inputAsTape,
			let tape = Recording(byteData: fileData) {
			recording = tape
		} else {
			let loadingAddress = UInt16(hexString: loadingAddress) ?? 0x1500
			let startAddress = UInt16(hexString: startAddress) ?? 0x1500
			guard let header = Header(
				name: String(name),
				fileLength: UInt16(fileData.count),
				loadingAddress: loadingAddress,
				startAddress: startAddress)
				else {
					throw MZError(message: "Couldn't create header for tape file.")
			}
			recording = Recording(header: header, data: fileData)
		}

		print(recording.description)

		// Save recording as MZF tape file if needed
		if !inputAsTape {
			try recording.save(outputURL)
		} else if !audio {
			print("No output file needed.")
		}

		if audio {
			try recording.saveAudio(outputAudioURL, fast: fastAudio)
		}
	}
}

MZAppMake.main()
