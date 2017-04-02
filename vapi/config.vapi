[CCode (lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {

	/**
     * Package name.
     */
	public const string PACKAGE_NAME;

	/**
     * Package string.
     */
	public const string PACKAGE_STRING;

	/**
     * Package version.
     */
	public const string PACKAGE_VERSION;

	/**
     * Gettext package.
     */
	public const string GETTEXT_PACKAGE;

    /**
     * Locale dir.
     */
	public const string LOCALEDIR;

    /**
     * Package data dir.
     */
	public const string PKGDATADIR;

    /**
     * Package library dir.
     */
    public const string PKGLIBDIR;
}
