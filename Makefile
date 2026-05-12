PORTNAME=	mailman2-python3
DISTVERSION=	2.1.39
CATEGORIES=	mail

MAINTAINER=	freebsd@gushi.org
COMMENT=	Mailman 2 mailing list manager ported to Python 3
WWW=		https://www.list.org/

LICENSE=	GPLv2
LICENSE_FILE=	${WRKSRC}/gnu-COPYING-GPL

CONFLICTS_INSTALL=	ja-mailman-2.1.* mailman*exim* mailman*postfix* mailman-2.*
USES=		cpe fakeroot python:3.9+ shebangfix
CPE_VENDOR=	gnu
USE_GITHUB=	yes
GH_ACCOUNT=	thegushi
GH_PROJECT=	mailman2-python3
GH_TAGNAME=	898bbd03244345cf5bde65a887b0f7a8fd1e8538
USE_RC_SUBR=	mailman
SHEBANG_FILES=	bin/msgfmt.py \
		scripts/convert_to_utf8 \
		tests/fblast.py \
		tests/onebounce.py

BUILD_DEPENDS+=	${PYTHON_PKGNAMEPREFIX}dnspython>=0:dns/py-dnspython@${PY_FLAVOR}
RUN_DEPENDS+=	${PYTHON_PKGNAMEPREFIX}dnspython>=0:dns/py-dnspython@${PY_FLAVOR}

GNU_CONFIGURE=	yes
GNU_CONFIGURE_PREFIX=	${MAILMANDIR}
CONFIGURE_ARGS+=	--with-python=${PYTHON_CMD} \
			--with-username=${MM_USERNAME} \
			--with-groupname=${MM_GROUPNAME} \
			--with-mail-gid=${MAIL_GID} --with-cgi-gid=${CGI_GID} \
			--with-permcheck=no \
			--with-mailhost=localhost \
			--with-urlhost=localhost
# setting these defeats the automated check for users in configure[.in], as of 2.1.39,
# implemented in MM_FIND_* macros:
CONFIGURE_ENV+=	CGI_GROUP=${CGI_GID} \
		MAIL_GROUP=${MAIL_GID} \
		MAILMAN_USER=${MM_USERNAME} \
		MAILMAN_GROUP=${MM_GROUPNAME}

# The Mailman port supports a number of variables that may be tweaked at
# build time.  Getting the values of some of them right is crucial!
#
MM_USERNAME?=	mailman
MM_USERID?=	91
MM_GROUPNAME?=	${MM_USERNAME}
MM_GROUPID?=	${MM_USERID}
MM_DIR?=	mailman
CGI_GID?=	www
IMGDIR?=	www/icons
#
# End of user-configurable variables.

USERS=		${MM_USERNAME}
GROUPS=		${MM_GROUPNAME}

MAILMANDIR=	${PREFIX}/${MM_DIR}
PLIST_SUB=	MMDIR=${MM_DIR} IMGDIR=${IMGDIR} MM_USERNAME=${MM_USERNAME} MM_GROUPNAME=${MM_GROUPNAME} \
		SUB_HTDIG="@comment "
SUB_FILES=	pkg-message pkg-install mailman.newsyslog.sample
SUB_LIST=	MAILMANDIR=${MAILMANDIR} USER=${MM_USERNAME} GROUP=${MM_GROUPNAME} PYTHON_CMD="${PYTHON_CMD}"
PKGDEINSTALL=	${PKGINSTALL}

PORTDOCS=	ACKNOWLEDGMENTS BUGS FAQ INSTALL NEWS README README-I18N.en \
		README.CONTRIB README.NETSCAPE \
		README.USERAGENT TODO UPGRADING \
		mailman-admin.txt \
		mailman-install.txt \
		mailman-member.txt \
		FreeBSD-post-install-notes

OPTIONS_SINGLE=		MTA
OPTIONS_SINGLE_MTA=	COURIER EXIM4 OPENSMTPD POSTFIX SENDMAIL
OPTIONS_DEFINE=		NOMAILPWD NLS DOCS
OPTIONS_DEFAULT=	SENDMAIL NOMAILPWD
COURIER_DESC=		for use with courier
EXIM4_DESC=		for use with exim4
EXIM4_RUN_DEPENDS=	exim>=0:mail/exim
OPENSMTPD_DESC=		for use with opensmtpd - EXPERIMENTAL -
POSTFIX_DESC=		for use with postfix
POSTFIX_RUN_DEPENDS=	postfix:mail/postfix
SENDMAIL_DESC=		for use with sendmail
NOMAILPWD_DESC=		Elide plaintext passwords from monthly reminders
MTA_DESC=		Integrate with which MTA?

.include <bsd.port.options.mk>

SUB_LIST+=	NLS="${PORT_OPTIONS:MNLS}"

# enforce EXAMPLES option, necessary so that @sample
# can install the newsyslog file
.if empty(PORT_OPTIONS:MEXAMPLES)
PORT_OPTIONS+=	EXAMPLES
.endif

.if ${PORT_OPTIONS:MNLS}
USES+=		gettext
PLIST_SUB+=	NLS=""
.else
PLIST_SUB+=	NLS="@comment "
MAKE_ARGS+=	LANGUAGES=en
.endif

.if ${PORT_OPTIONS:MSENDMAIL}
MAIL_GID?=	mailnull
.endif

.if ${PORT_OPTIONS:MEXIM4}
MAIL_GID?=	mail
.endif

.if ${PORT_OPTIONS:MPOSTFIX}
MAIL_GID?=	mailman
EXTRA_PATCHES+=	${FILESDIR}/postfix-verp.diff
.endif

.if ${PORT_OPTIONS:MCOURIER}
MAIL_GID?=	courier
.endif

.if ${PORT_OPTIONS:MOPENSMTPD}
MAIL_GID?=	_smtpd
.endif

.if ${PORT_OPTIONS:MNOMAILPWD}
EXTRA_PATCHES+=	${FILESDIR}/extra-patch-mailpasswds
.endif

pre-everything::
	@${ECHO} ""
	@${ECHO} "You may change the following build options:"
	@${ECHO} ""
	@${ECHO} "Option		Default Value	Description"
	@${ECHO} "-------------	---------------	------------------------------------------------"
	@${ECHO} "MM_USERNAME	mailman		The username of the Mailman user."
	@${ECHO} "MM_USERID	91		The user ID of the Mailman user."
	@${ECHO} "MM_GROUPNAME	mailman		The group to which the Mailman user will belong."
	@${ECHO} "MM_GROUPID	\$$MM_USERID	The group ID for the Mailman user."
	@${ECHO} "MM_DIR		mailman		Mailman will be installed in"
	@${ECHO} "				${PREFIX}/${MM_DIR}."
	@${ECHO} "CGI_GID		www		The group name or id under which your web"
	@${ECHO} "				server executes CGI scripts."
	@${ECHO} "IMGDIR		www/icons	Icon images will be installed in"
	@${ECHO} "				${PREFIX}/${IMGDIR}."
	@${ECHO} ""

post-patch:
	${REINPLACE_CMD} -e 's#%%LOCALBASE%%#${LOCALBASE}#g' \
	  ${WRKSRC}/Mailman/Defaults.py.in
	${REINPLACE_CMD} -e 's/^0,5,10/#&/' ${WRKSRC}/cron/crontab.in.in
.if empty(PORT_OPTIONS:MNLS)
	${REINPLACE_CMD} -e 's/messages//' ${WRKSRC}/Makefile.in
.endif

post-install:
	${MKDIR} ${STAGEDIR}${EXAMPLESDIR}
	${INSTALL_DATA} ${WRKDIR}/mailman.newsyslog.sample ${STAGEDIR}${EXAMPLESDIR}
.for i in admindb admin confirm create edithtml listinfo options private \
	rmlist roster subscribe
	${STRIP_CMD} ${STAGEDIR}${MAILMANDIR}/cgi-bin/${i}
.endfor
	${STRIP_CMD} ${STAGEDIR}${MAILMANDIR}/mail/mailman
	@${RM} -f ${STAGEDIR}${MAILMANDIR}/pythonlib/*.egg-info 2>/dev/null || true
	@${RM} -f ${STAGEDIR}${MAILMANDIR}/Mailman/mm_cfg.py
	@${MKDIR} ${STAGEDIR}${PREFIX}/${IMGDIR}
	${CP} -p ${STAGEDIR}${MAILMANDIR}/icons/* ${STAGEDIR}${PREFIX}/${IMGDIR}
	${INSTALL_DATA} ${FILESDIR}/powerlogo.png \
	  ${STAGEDIR}${PREFIX}/${IMGDIR}/
	${INSTALL_DATA} ${FILESDIR}/powerlogo.png \
	  ${STAGEDIR}${MAILMANDIR}/icons/
.if ${PORT_OPTIONS:MDOCS}
	${CP} -R ${WRKSRC}/doc/* ${WRKSRC}/
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${FILESDIR}/FreeBSD-post-install-notes ${STAGEDIR}${DOCSDIR}
.for docfile in ${PORTDOCS:NFreeBSD-post-install-notes}
	${INSTALL_DATA} ${WRKSRC}/${docfile} ${STAGEDIR}${DOCSDIR}
.endfor
.endif
	@${MKDIR} ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}
	${ECHO} "This marker file ensures that Python's upgrade-site-packages handles ${PKGNAME}." >${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}/mailman-info.txt
	${INSTALL_SCRIPT} ${PKGINSTALL} ${STAGEDIR}${MAILMANDIR}/bin/FreeBSD-post-install
	${MKDIR} ${STAGEDIR}${MAILMANDIR}/templates/site/en
	${INSTALL_DATA} ${FILESDIR}/templates_site_README.txt ${STAGEDIR}${MAILMANDIR}/templates/site/README.txt

.include <bsd.port.mk>
