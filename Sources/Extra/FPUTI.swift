//
//  FPUTI.swift
//  fseventstool
//
//  Created by Matthias Keiser on 09.01.17.
//  Copyright © 2017 Tristan Inc. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS)
	import MobileCoreServices
#elseif os(macOS)
	import CoreServices
#endif

/// Instances of the FPUTI class represent a specific Universal Type Identifier, e.g. kUTTypeMPEG4.

public class FPUTI: RawRepresentable, Equatable {

	/**
	The TagClass enum represents the supported tag classes.
	
	- fileExtension: kUTTagClassFilenameExtension
	- mimeType: kUTTagClassMIMEType
	- pbType: kUTTagClassNSPboardType
	- osType: kUTTagClassOSType
	*/
	public enum TagClass: String {

		/// Equivalent to kUTTagClassFilenameExtension
		case fileExtension = "public.filename-extension"

		/// Equivalent to kUTTagClassMIMEType
		case mimeType = "public.mime-type"

		#if os (macOS)

		/// Equivalent to kUTTagClassNSPboardType
		case pbType =  "com.apple.nspboard-type"

		/// Equivalent to kUTTagClassOSType
		case osType =  "com.apple.ostype"
		#endif

		/// Convenience variable for internal use.
		
		fileprivate var rawCFValue: CFString {
			return self.rawValue as CFString
		}
	}

	public typealias RawValue = String
	public let rawValue: String


	/// Convenience variable for internal use.

	private var rawCFValue: CFString {

		return self.rawValue as CFString
	}

	// MARK: Initialization


	/**
	
	This is the designated initializer of the FPUTI class.
	
	 - Parameters:
			- rawValue: A string that is a Universal Type Identifier, i.e. "com.foobar.baz" or a constant like kUTTypeMP3.
	 - Returns:
			An FPUTI instance representing the specified rawValue.
	 - Note:
			You should rarely use this method. The preferred way to initialize a known FPUTI is to use its static variable (i.e. FPUTI.pdf). You should make an extension to make your own types available as static variables.
	
	*/

	public required init(rawValue: FPUTI.RawValue) {

		self.rawValue = rawValue
	}

	/**

	Initialize an FPUTI with a tag of a specified class.

	- Parameters:
		- tagClass: The class of the tag.
		- value: The value of the tag.
		- conformingTo: If specified, the returned FPUTI must conform to this FPUTI. If nil is specified, this parameter is ignored. The default is nil.
	- Returns:
		An FPUTI instance representing the specified rawValue. If no known FPUTI with the specified tags is found, a dynamic FPUTI is created.
	- Note:
		You should rarely need this method. It's usually simpler to use one of the specialized initialzers like
		```convenience init?(withExtension fileExtension: String, conformingTo conforming: FPUTI? = nil)```
	*/

	public convenience init(withTagClass tagClass: TagClass, value: String, conformingTo conforming: FPUTI? = nil) {

		let unmanagedIdentifier = UTTypeCreatePreferredIdentifierForTag(tagClass.rawCFValue, value as CFString, conforming?.rawCFValue)

		// UTTypeCreatePreferredIdentifierForTag only returns nil if the tag class is unknwown, which can't happen to us since we use an
		// enum of known values. Hence we can force-cast the result.

        let identifier = (unmanagedIdentifier?.takeRetainedValue() as String?)!

		self.init(rawValue: identifier)
	}

	/**

	Initialize an FPUTI with a file extension.
	
	- Parameters:
		- withExtension: The file extension (e.g. "txt").
		- conformingTo: If specified, the returned FPUTI must conform to this FPUTI. If nil is specified, this parameter is ignored. The default is nil.
	- Returns: 
		An FPUTI corresponding to the specified values.
	**/

	public convenience init(withExtension fileExtension: String, conformingTo conforming: FPUTI? = nil) {

		self.init(withTagClass:.fileExtension, value: fileExtension, conformingTo: conforming)
	}

	/**

	Initialize an FPUTI with a MIME type.
	
	- Parameters:
		- mimeType: The MIME type (e.g. "text/plain").
		- conformingTo: If specified, the returned FPUTI must conform to this FPUTI. If nil is specified, this parameter is ignored. The default is nil.
	- Returns:
		An FPUTI corresponding to the specified values.
	*/

	public convenience init(withMimeType mimeType: String, conformingTo conforming: FPUTI? = nil) {

		self.init(withTagClass:.mimeType, value: mimeType, conformingTo: conforming)
	}

	#if os(macOS)

	/**

	Initialize an FPUTI with a pasteboard type.
    - Important: **This function is de-facto deprecated!** The old cocoa pasteboard types ( `NSStringPboardType`, `NSPDFPboardType`, etc) have been deprecated in favour of actual FPUTIs, and the constants are not available anymore in Swift. This function only works correctly with the values of these old constants, but _not_ with the replacement values (like `NSPasteboardTypeString` etc), since these already are FPUTIs.
	- Parameters:
		- pbType: The pasteboard type (e.g. NSPDFPboardType).
		- conformingTo: If specified, the returned FPUTI must conform to this FPUTI. If nil is specified, this parameter is ignored. The default is nil.
	- Returns:
		An FPUTI corresponding to the specified values.
	*/
	public convenience init(withPBType pbType: String, conformingTo conforming: FPUTI? = nil) {

		self.init(withTagClass:.pbType, value: pbType, conformingTo: conforming)
	}

	/**
	Initialize an FPUTI with a OSType.
	
	- Parameters:
		- osType: The OSType type as a string (e.g. "PDF ").
		- conformingTo: If specified, the returned FPUTI must conform to this FPUTI. If nil is specified, this parameter is ignored. The default is nil.
	- Returns:
		An FPUTI corresponding to the specified values.
	- Note:
		You can use the variable ```OSType.string``` to get a string from an actual OSType.
	*/

	public convenience init(withOSType osType: String, conformingTo conforming: FPUTI? = nil) {

		self.init(withTagClass:.osType, value: osType, conformingTo: conforming)
	}

	#endif

	// MARK: Accessing Tags

	/**

	Returns the tag with the specified class.
	
	- Parameters:
		- tagClass: The tag class to return.
	- Returns:
		The requested tag, or nil if there is no tag of the specified class.
	*/

	public func tag(with tagClass: TagClass) -> String? {

		let unmanagedTag = UTTypeCopyPreferredTagWithClass(self.rawCFValue, tagClass.rawCFValue)

		guard let tag = unmanagedTag?.takeRetainedValue() as String? else {
			return nil
		}

		return tag
	}

	/// Return the file extension that corresponds the the FPUTI. Returns nil if not available.

	public var fileExtension: String? {

		return self.tag(with: .fileExtension)
	}

	/// Return the MIME type that corresponds the the FPUTI. Returns nil if not available.

	public var mimeType: String? {

		return self.tag(with: .mimeType)
	}

	#if os(macOS)

	/// Return the pasteboard type that corresponds the the FPUTI. Returns nil if not available.

	public var pbType: String? {

		return self.tag(with: .pbType)
	}

	/// Return the OSType as a string that corresponds the the FPUTI. Returns nil if not available.
	/// - Note: you can use the ```init(with string: String)``` initializer to construct an actual OSType from the returnes string.

	public var osType: String? {

		return self.tag(with: .osType)
	}

	#endif

	/**

	Returns all tags of the specified tag class.
	
	- Parameters:
		- tagClass: The class of the requested tags.
	- Returns:
		An array of all tags of the receiver of the specified class.
	*/

	public func tags(with tagClass: TagClass) -> Array<String> {

		let unmanagedTags = UTTypeCopyAllTagsWithClass(self.rawCFValue, tagClass.rawCFValue)

		guard let tags = unmanagedTags?.takeRetainedValue() as? Array<CFString> else {
			return []
		}

		return tags as Array<String>
	}

	// MARK: List all FPUTIs associated with a tag


	/**
	Returns all FPUTIs that are associated with a specified tag.
	
	- Parameters:
	  - tag: The class of the specified tag.
	  - value: The value of the tag.
	  - conforming: If specified, the returned FPUTIs must conform to this FPUTI. If nil is specified, this parameter is ignored. The default is nil.
	- Returns:
		An array of all FPUTIs that satisfy the specified parameters.
	*/

	public static func FPUTIs(for tag: TagClass, value: String, conformingTo conforming: FPUTI? = nil) -> Array<FPUTI> {

		let unmanagedIdentifiers = UTTypeCreateAllIdentifiersForTag(tag.rawCFValue, value as CFString, conforming?.rawCFValue)


		guard let identifiers = unmanagedIdentifiers?.takeRetainedValue() as? Array<CFString> else {
			return []
		}

		return identifiers.compactMap { FPUTI(rawValue: $0 as String) }
	}

	// MARK: Equality and Conformance to other FPUTIs

	/**

	Checks if the receiver conforms to a specified FPUTI.
	
	- Parameters:
		- otherFPUTI: The FPUTI to which the receiver is compared.
	- Returns:
		```true``` if the receiver conforms to the specified FPUTI, ```false```otherwise.
	*/

	public func conforms(to otherFPUTI: FPUTI) -> Bool {

		return UTTypeConformsTo(self.rawCFValue, otherFPUTI.rawCFValue) as Bool
	}

	public static func ==(lhs: FPUTI, rhs: FPUTI) -> Bool {

		return UTTypeEqual(lhs.rawCFValue, rhs.rawCFValue) as Bool
	}

	// MARK: Accessing Information about an FPUTI

	/// Returns the localized, user-readable type description string associated with a uniform type identifier.
	
	public var description: String? {

		let unmanagedDescription = UTTypeCopyDescription(self.rawCFValue)

		guard let description = unmanagedDescription?.takeRetainedValue() as String? else {
			return nil
		}

		return description
	}

	/// Returns a uniform type’s declaration as a Dictionary, or nil if if no declaration for that type can be found.

	public var declaration: [AnyHashable:Any]? {

		let unmanagedDeclaration = UTTypeCopyDeclaration(self.rawCFValue)

		guard let declaration = unmanagedDeclaration?.takeRetainedValue() as? [AnyHashable:Any] else {
			return nil
		}

		return declaration
	}

	/// Returns the location of a bundle containing the declaration for a type, or nil if the bundle could not be located.

	public var declaringBundleURL: URL? {

		let unmanagedURL = UTTypeCopyDeclaringBundleURL(self.rawCFValue)

		guard let url = unmanagedURL?.takeRetainedValue() as URL? else {
			return nil
		}

		return url
	}

	/// Returns ```true``` if the receiver is a dynamic FPUTI.

	public var isDynamic: Bool {

		return UTTypeIsDynamic(self.rawCFValue)
	}
}


// MARK: System defined FPUTIs

public extension FPUTI {

	static       let  item                        =    FPUTI(rawValue:  kUTTypeItem                        as  String)
	static       let  content                     =    FPUTI(rawValue:  kUTTypeContent                     as  String)
	static       let  compositeContent            =    FPUTI(rawValue:  kUTTypeCompositeContent            as  String)
	static       let  message                     =    FPUTI(rawValue:  kUTTypeMessage                     as  String)
	static       let  contact                     =    FPUTI(rawValue:  kUTTypeContact                     as  String)
	static       let  archive                     =    FPUTI(rawValue:  kUTTypeArchive                     as  String)
	static       let  diskImage                   =    FPUTI(rawValue:  kUTTypeDiskImage                   as  String)
	static       let  data                        =    FPUTI(rawValue:  kUTTypeData                        as  String)
	static       let  directory                   =    FPUTI(rawValue:  kUTTypeDirectory                   as  String)
	static       let  resolvable                  =    FPUTI(rawValue:  kUTTypeResolvable                  as  String)
	static       let  symLink                     =    FPUTI(rawValue:  kUTTypeSymLink                     as  String)
	static       let  executable                  =    FPUTI(rawValue:  kUTTypeExecutable                  as  String)
	static       let  mountPoint                  =    FPUTI(rawValue:  kUTTypeMountPoint                  as  String)
	static       let  aliasFile                   =    FPUTI(rawValue:  kUTTypeAliasFile                   as  String)
	static       let  aliasRecord                 =    FPUTI(rawValue:  kUTTypeAliasRecord                 as  String)
	static       let  urlBookmarkData             =    FPUTI(rawValue:  kUTTypeURLBookmarkData             as  String)
	static       let  url                         =    FPUTI(rawValue:  kUTTypeURL                         as  String)
	static       let  fileURL                     =    FPUTI(rawValue:  kUTTypeFileURL                     as  String)
	static       let  text                        =    FPUTI(rawValue:  kUTTypeText                        as  String)
	static       let  plainText                   =    FPUTI(rawValue:  kUTTypePlainText                   as  String)
	static       let  utf8PlainText               =    FPUTI(rawValue:  kUTTypeUTF8PlainText               as  String)
	static       let  utf16ExternalPlainText      =    FPUTI(rawValue:  kUTTypeUTF16ExternalPlainText      as  String)
	static       let  utf16PlainText              =    FPUTI(rawValue:  kUTTypeUTF16PlainText              as  String)
	static       let  delimitedText               =    FPUTI(rawValue:  kUTTypeDelimitedText               as  String)
	static       let  commaSeparatedText          =    FPUTI(rawValue:  kUTTypeCommaSeparatedText          as  String)
	static       let  tabSeparatedText            =    FPUTI(rawValue:  kUTTypeTabSeparatedText            as  String)
	static       let  utf8TabSeparatedText        =    FPUTI(rawValue:  kUTTypeUTF8TabSeparatedText        as  String)
	static       let  rtf                         =    FPUTI(rawValue:  kUTTypeRTF                         as  String)
	static       let  html                        =    FPUTI(rawValue:  kUTTypeHTML                        as  String)
	static       let  xml                         =    FPUTI(rawValue:  kUTTypeXML                         as  String)
	static       let  sourceCode                  =    FPUTI(rawValue:  kUTTypeSourceCode                  as  String)
	static       let  assemblyLanguageSource      =    FPUTI(rawValue:  kUTTypeAssemblyLanguageSource      as  String)
	static       let  cSource                     =    FPUTI(rawValue:  kUTTypeCSource                     as  String)
	static       let  objectiveCSource            =    FPUTI(rawValue:  kUTTypeObjectiveCSource            as  String)
	@available( OSX 10.11, iOS 9.0, * )
	static       let  swiftSource				  =    FPUTI(rawValue:  kUTTypeSwiftSource				 as  String)
	static       let  cPlusPlusSource             =    FPUTI(rawValue:  kUTTypeCPlusPlusSource             as  String)
	static       let  objectiveCPlusPlusSource    =    FPUTI(rawValue:  kUTTypeObjectiveCPlusPlusSource    as  String)
	static       let  cHeader                     =    FPUTI(rawValue:  kUTTypeCHeader                     as  String)
	static       let  cPlusPlusHeader             =    FPUTI(rawValue:  kUTTypeCPlusPlusHeader             as  String)
	static       let  javaSource                  =    FPUTI(rawValue:  kUTTypeJavaSource                  as  String)
	static       let  script                      =    FPUTI(rawValue:  kUTTypeScript                      as  String)
	static       let  appleScript                 =    FPUTI(rawValue:  kUTTypeAppleScript                 as  String)
	static       let  osaScript                   =    FPUTI(rawValue:  kUTTypeOSAScript                   as  String)
	static       let  osaScriptBundle             =    FPUTI(rawValue:  kUTTypeOSAScriptBundle             as  String)
	static       let  javaScript                  =    FPUTI(rawValue:  kUTTypeJavaScript                  as  String)
	static       let  shellScript                 =    FPUTI(rawValue:  kUTTypeShellScript                 as  String)
	static       let  perlScript                  =    FPUTI(rawValue:  kUTTypePerlScript                  as  String)
	static       let  pythonScript                =    FPUTI(rawValue:  kUTTypePythonScript                as  String)
	static       let  rubyScript                  =    FPUTI(rawValue:  kUTTypeRubyScript                  as  String)
	static       let  phpScript                   =    FPUTI(rawValue:  kUTTypePHPScript                   as  String)
	static       let  json                        =    FPUTI(rawValue:  kUTTypeJSON                        as  String)
	static       let  propertyList                =    FPUTI(rawValue:  kUTTypePropertyList                as  String)
	static       let  xmlPropertyList             =    FPUTI(rawValue:  kUTTypeXMLPropertyList             as  String)
	static       let  binaryPropertyList          =    FPUTI(rawValue:  kUTTypeBinaryPropertyList          as  String)
	static       let  pdf                         =    FPUTI(rawValue:  kUTTypePDF                         as  String)
	static       let  rtfd                        =    FPUTI(rawValue:  kUTTypeRTFD                        as  String)
	static       let  flatRTFD                    =    FPUTI(rawValue:  kUTTypeFlatRTFD                    as  String)
	static       let  txnTextAndMultimediaData    =    FPUTI(rawValue:  kUTTypeTXNTextAndMultimediaData    as  String)
	static       let  webArchive                  =    FPUTI(rawValue:  kUTTypeWebArchive                  as  String)
	static       let  image                       =    FPUTI(rawValue:  kUTTypeImage                       as  String)
	static       let  jpeg                        =    FPUTI(rawValue:  kUTTypeJPEG                        as  String)
	static       let  jpeg2000                    =    FPUTI(rawValue:  kUTTypeJPEG2000                    as  String)
	static       let  tiff                        =    FPUTI(rawValue:  kUTTypeTIFF                        as  String)
	static       let  pict                        =    FPUTI(rawValue:  kUTTypePICT                        as  String)
	static       let  gif                         =    FPUTI(rawValue:  kUTTypeGIF                         as  String)
	static       let  png                         =    FPUTI(rawValue:  kUTTypePNG                         as  String)
	static       let  quickTimeImage              =    FPUTI(rawValue:  kUTTypeQuickTimeImage              as  String)
	static       let  appleICNS                   =    FPUTI(rawValue:  kUTTypeAppleICNS                   as  String)
	static       let  bmp                         =    FPUTI(rawValue:  kUTTypeBMP                         as  String)
	static       let  ico                         =    FPUTI(rawValue:  kUTTypeICO                         as  String)
	static       let  rawImage                    =    FPUTI(rawValue:  kUTTypeRawImage                    as  String)
	static       let  scalableVectorGraphics      =    FPUTI(rawValue:  kUTTypeScalableVectorGraphics      as  String)
	@available(OSX 10.12, iOS 9.1, watchOS 2.1, *)
	static       let  livePhoto					  =    FPUTI(rawValue:  kUTTypeLivePhoto					 as  String)
	@available(OSX 10.12, iOS 9.1, *)
	static       let  audiovisualContent          =    FPUTI(rawValue:  kUTTypeAudiovisualContent          as  String)
	static       let  movie                       =    FPUTI(rawValue:  kUTTypeMovie                       as  String)
	static       let  video                       =    FPUTI(rawValue:  kUTTypeVideo                       as  String)
	static       let  audio                       =    FPUTI(rawValue:  kUTTypeAudio                       as  String)
	static       let  quickTimeMovie              =    FPUTI(rawValue:  kUTTypeQuickTimeMovie              as  String)
	static       let  mpeg                        =    FPUTI(rawValue:  kUTTypeMPEG                        as  String)
	static       let  mpeg2Video                  =    FPUTI(rawValue:  kUTTypeMPEG2Video                  as  String)
	static       let  mpeg2TransportStream        =    FPUTI(rawValue:  kUTTypeMPEG2TransportStream        as  String)
	static       let  mp3                         =    FPUTI(rawValue:  kUTTypeMP3                         as  String)
	static       let  mpeg4                       =    FPUTI(rawValue:  kUTTypeMPEG4                       as  String)
	static       let  mpeg4Audio                  =    FPUTI(rawValue:  kUTTypeMPEG4Audio                  as  String)
	static       let  appleProtectedMPEG4Audio    =    FPUTI(rawValue:  kUTTypeAppleProtectedMPEG4Audio    as  String)
	static       let  appleProtectedMPEG4Video    =    FPUTI(rawValue:  kUTTypeAppleProtectedMPEG4Video    as  String)
	static       let  aviMovie                    =    FPUTI(rawValue:  kUTTypeAVIMovie                    as  String)
	static       let  audioInterchangeFileFormat  =    FPUTI(rawValue:  kUTTypeAudioInterchangeFileFormat  as  String)
	static       let  waveformAudio               =    FPUTI(rawValue:  kUTTypeWaveformAudio               as  String)
	static       let  midiAudio                   =    FPUTI(rawValue:  kUTTypeMIDIAudio                   as  String)
	static       let  playlist                    =    FPUTI(rawValue:  kUTTypePlaylist                    as  String)
	static       let  m3UPlaylist                 =    FPUTI(rawValue:  kUTTypeM3UPlaylist                 as  String)
	static       let  folder                      =    FPUTI(rawValue:  kUTTypeFolder                      as  String)
	static       let  volume                      =    FPUTI(rawValue:  kUTTypeVolume                      as  String)
	static       let  package                     =    FPUTI(rawValue:  kUTTypePackage                     as  String)
	static       let  bundle                      =    FPUTI(rawValue:  kUTTypeBundle                      as  String)
	static       let  pluginBundle                =    FPUTI(rawValue:  kUTTypePluginBundle                as  String)
	static       let  spotlightImporter           =    FPUTI(rawValue:  kUTTypeSpotlightImporter           as  String)
	static       let  quickLookGenerator          =    FPUTI(rawValue:  kUTTypeQuickLookGenerator          as  String)
	static       let  xpcService                  =    FPUTI(rawValue:  kUTTypeXPCService                  as  String)
	static       let  framework                   =    FPUTI(rawValue:  kUTTypeFramework                   as  String)
	static       let  application                 =    FPUTI(rawValue:  kUTTypeApplication                 as  String)
	static       let  applicationBundle           =    FPUTI(rawValue:  kUTTypeApplicationBundle           as  String)
	static       let  applicationFile             =    FPUTI(rawValue:  kUTTypeApplicationFile             as  String)
	static       let  unixExecutable              =    FPUTI(rawValue:  kUTTypeUnixExecutable              as  String)
	static       let  windowsExecutable           =    FPUTI(rawValue:  kUTTypeWindowsExecutable           as  String)
	static       let  javaClass                   =    FPUTI(rawValue:  kUTTypeJavaClass                   as  String)
	static       let  javaArchive                 =    FPUTI(rawValue:  kUTTypeJavaArchive                 as  String)
	static       let  systemPreferencesPane       =    FPUTI(rawValue:  kUTTypeSystemPreferencesPane       as  String)
	static       let  gnuZipArchive               =    FPUTI(rawValue:  kUTTypeGNUZipArchive               as  String)
	static       let  bzip2Archive                =    FPUTI(rawValue:  kUTTypeBzip2Archive                as  String)
	static       let  zipArchive                  =    FPUTI(rawValue:  kUTTypeZipArchive                  as  String)
	static       let  spreadsheet                 =    FPUTI(rawValue:  kUTTypeSpreadsheet                 as  String)
	static       let  presentation                =    FPUTI(rawValue:  kUTTypePresentation                as  String)
	static       let  database                    =    FPUTI(rawValue:  kUTTypeDatabase                    as  String)
	static       let  vCard                       =    FPUTI(rawValue:  kUTTypeVCard                       as  String)
	static       let  toDoItem                    =    FPUTI(rawValue:  kUTTypeToDoItem                    as  String)
	static       let  calendarEvent               =    FPUTI(rawValue:  kUTTypeCalendarEvent               as  String)
	static       let  emailMessage                =    FPUTI(rawValue:  kUTTypeEmailMessage                as  String)
	static       let  internetLocation            =    FPUTI(rawValue:  kUTTypeInternetLocation            as  String)
	static       let  inkText                     =    FPUTI(rawValue:  kUTTypeInkText                     as  String)
	static       let  font                        =    FPUTI(rawValue:  kUTTypeFont                        as  String)
	static       let  bookmark                    =    FPUTI(rawValue:  kUTTypeBookmark                    as  String)
	static       let  _3DContent                  =    FPUTI(rawValue:  kUTType3DContent                   as  String)
	static       let  pkcs12                      =    FPUTI(rawValue:  kUTTypePKCS12                      as  String)
	static       let  x509Certificate             =    FPUTI(rawValue:  kUTTypeX509Certificate             as  String)
	static       let  electronicPublication       =    FPUTI(rawValue:  kUTTypeElectronicPublication       as  String)
	static       let  log                         =    FPUTI(rawValue:  kUTTypeLog                         as  String)
}

#if os(OSX)

	extension OSType {


		/// Returns the OSType encoded as a String.

		var string: String {

			let unmanagedString = UTCreateStringForOSType(self)

			return unmanagedString.takeRetainedValue() as String
		}


		/// Initializes a OSType from a String.
		///
		/// - Parameter string: A String representing an OSType.
		
		init(with string: String) {
			
			self = UTGetOSTypeFromString(string as CFString)
		}
	}
	
#endif
