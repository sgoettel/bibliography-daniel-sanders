<?xml version="1.0" encoding="UTF-8"?>
<!--
===============================================================================
  XSLT Stylesheet for Transforming Bibliographic Data
===============================================================================

  This stylesheet was primarily created for the bibliography of
  Daniel Sanders (1819–1897):

      https://sanders.bbaw.de/bibliographie

  Of course, this stylesheet can also be used for other TEI
  bibliographies exported from Zotero.
  However, for non-german citations, you may need to adjust certain abbreviations,
  such as replacing "S." (=Seite)) with p. (=page), Hrsg. with ed.
  
  Example output formats:

  1. Book:
     Doe, John: Example Book Title. Berlin: Example Publisher 2020.

  2. Book Section:
     Doe, John: Example Chapter Title. In: Smith, Jane, The Study of Languages. 
     London: Example Publisher, p. 123–134.

  3. Book Section (if `t:biblScope[@unit='volume']` is used; multi-volume work):
     Doe, John: Example Chapter Title. In: Alice Brown (ed.), The Great Anthology of Literature, vol. 3. 
     Mannheim: Example Press, p. 76–87.

  4. Journal Article:
     Doe, John: Example Article Title. In: Example Journal, ed. by Smith, Jane, vol. 5 (2023), p. 21–25.

  4. Newspaper Article:
     Doe, John: Example News Article Title. In: Example Newspaper: Morning Edition, 
     New York, 10. July 2022, p. 4.


  If available, the following elements are appended to each citation:  
  [Digitalisat] Zotero Icon <small>Additional bibliographic notes.</small>


  sgoettel, 2025.
===============================================================================
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="t xs">

    <!-- Output Method and Encoding -->
    <xsl:output method="html" media-type="text/html" cdata-section-elements="script style"
        indent="no" encoding="utf-8"/>

    <!-- Suppress teiHeader output -->
    <xsl:template match="t:teiHeader"/>

    <!-- ========================= Named Template for Conditional Sentence Ending ========================= -->
    <xsl:template name="add-period-if-needed">
        <xsl:param name="text"/>
        <xsl:variable name="clean-text" select="normalize-space($text)"/>
        <xsl:variable name="last-char"
            select="substring($clean-text, string-length($clean-text), 1)"/>
        <xsl:if test="not(contains('.!?…', $last-char))">
            <xsl:text>.</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- ========================= Named Template for Date Formatting ========================= -->
    <xsl:template name="format-date">
        <xsl:param name="date" select="t:monogr/t:imprint/t:date"/>

        <xsl:choose>
            <!-- If the date is in the expected format YYYY-MM-DD -->
            <xsl:when
                test="string-length($date) = 10 and substring($date, 5, 1) = '-' and substring($date, 8, 1) = '-'">

                <!-- Extract year, month, and day -->
                <xsl:variable name="year" select="substring($date, 1, 4)"/>
                <xsl:variable name="month" select="number(substring($date, 6, 2))"/>
                <xsl:variable name="day" select="number(substring($date, 9, 2))"/>
                <!-- `number()` automatically removes leading zeros from single-digit days -->

                <!-- Lookup table for month names -->
                <xsl:variable name="month-names"
                    select="'Januar Februar März April Mai Juni Juli August September Oktober November Dezember'"/>

                <!-- Extract the correct month name -->
                <xsl:variable name="month-name">
                    <xsl:choose>
                        <xsl:when test="$month = 1">Januar</xsl:when>
                        <xsl:when test="$month = 2">Februar</xsl:when>
                        <xsl:when test="$month = 3">März</xsl:when>
                        <xsl:when test="$month = 4">April</xsl:when>
                        <xsl:when test="$month = 5">Mai</xsl:when>
                        <xsl:when test="$month = 6">Juni</xsl:when>
                        <xsl:when test="$month = 7">Juli</xsl:when>
                        <xsl:when test="$month = 8">August</xsl:when>
                        <xsl:when test="$month = 9">September</xsl:when>
                        <xsl:when test="$month = 10">Oktober</xsl:when>
                        <xsl:when test="$month = 11">November</xsl:when>
                        <xsl:when test="$month = 12">Dezember</xsl:when>
                    </xsl:choose>
                </xsl:variable>

                <!-- output formatted date: day without leading zero + month name + year -->
                <xsl:value-of select="concat($day, '. ', $month-name, ' ', $year)"/>
            </xsl:when>

            <!-- If the date is not in the expected format, output as-is -->
            <xsl:when test="normalize-space($date) != ''">
                <xsl:value-of select="$date"/>
            </xsl:when>

            <!-- If no date exists, output nothing -->
        </xsl:choose>
    </xsl:template>

    <!-- ========================= Template for URL Notes ========================= -->
    <xsl:template match="t:note[@type = 'url']">
        <xsl:text>[</xsl:text>
        <a href="{text()}" target="_blank">Digitalisat</a>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <!-- ========================= Named Template for Zotero-link ========================= -->
    <xsl:template name="zotero-link">
        <xsl:param name="corresp"/>
        <xsl:if test="$corresp">
            <a href="{$corresp}" target="_blank" class="ms-1" data-bs-toggle="tooltip"
                title="Zum Eintrag bei zotero.org">
                <img src="/static/img/zotero-icon.svg" alt="Icon Zotero" style="height:12pt"/>
            </a>
        </xsl:if>
    </xsl:template>

    <!-- Apply Zotero-link-template to all 'monogr' parts (journal title, volume, etc.) -->
    <xsl:template match="t:biblStruct" mode="zotero">
        <xsl:variable name="corresp" select="@corresp"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="zotero-link">
            <xsl:with-param name="corresp" select="$corresp"/>
        </xsl:call-template>
    </xsl:template>

    <!-- ========================= Named Template for Processing URL Notes ========================= -->
    <xsl:template name="process-url-note">
        <xsl:if test="t:monogr/t:imprint/t:note[@type = 'url']">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:monogr/t:imprint/t:note[@type = 'url']"/>
        </xsl:if>
    </xsl:template>

    <!-- ========================= Named Template for Processing Bibliographic Notes ========================= -->
    <xsl:template name="insert-bibliographic-note">
        <xsl:if test="t:note[@type = 'bibliographic']">
            <xsl:text> </xsl:text>
            <span style="font-size: smaller;">
                <xsl:call-template name="process-bibliographic-note">
                    <xsl:with-param name="text" select="t:note[@type = 'bibliographic']"/>
                </xsl:call-template>
            </span>
        </xsl:if>
    </xsl:template>


    <!-- ========================= Named Template for Processing Bibliographic Notes with Hyperlinks ========================= -->
    <xsl:template name="process-bibliographic-note">
        <xsl:param name="text"/>

        <xsl:analyze-string select="$text" regex="(https?://[^\s]+)">
            <!-- If URL within note, make it clickable -->
            <xsl:matching-substring>
                <a href="{.}" target="_blank">
                    <xsl:value-of select="."/>
                </a>
            </xsl:matching-substring>
            <!-- Normale Inhalte unverändert ausgeben -->
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>


    <!-- ========================= Template for Journal Articles (journalArticle) ========================= -->
    <xsl:template match="t:biblStruct[@type = 'journalArticle']">
        <div class="bibl-entry">
            <!-- Stores the 'corresp' attribute value for potential linking -->
            <xsl:variable name="corresp" select="@corresp"/>
            <!-- Apply templates to the 'analytic' part (author and title of the article) -->
            <xsl:apply-templates select="t:analytic"/>
            <xsl:call-template name="add-period-if-needed">
                <xsl:with-param name="text" select="string(t:analytic/t:title[@level = 'a'])"/>
            </xsl:call-template>
            <xsl:text> In: </xsl:text>

            <!-- Journal Title -->
            <xsl:apply-templates select="t:monogr/t:title[@level = 'j']"/>
            <!-- Editor (if any) -->
            <xsl:call-template name="format-editor">
                <xsl:with-param name="select" select="t:monogr/t:editor"/>
                <xsl:with-param name="context" select="'journal'"/>
            </xsl:call-template>
            <!-- Volume -->
            <xsl:if test="t:monogr/t:imprint/t:biblScope[@unit = 'volume']">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="t:monogr/t:imprint/t:biblScope[@unit = 'volume']"/>
            </xsl:if>
            <!-- Issue -->
            <xsl:if test="t:monogr/t:imprint/t:biblScope[@unit = 'issue']">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="t:monogr/t:imprint/t:biblScope[@unit = 'issue']"/>
            </xsl:if>
            <!-- Date -->
            <xsl:if test="t:monogr/t:imprint/t:date">
                <xsl:text> (</xsl:text>
                <xsl:call-template name="format-date">
                    <xsl:with-param name="date" select="t:monogr/t:imprint/t:date"/>
                </xsl:call-template>
                <xsl:text>)</xsl:text>
            </xsl:if>
            <!-- If page number exists, print it -->
            <xsl:if test="t:monogr/t:imprint/t:biblScope[@unit = 'page']">
                <xsl:text>, S. </xsl:text>
                <xsl:apply-templates select="t:monogr/t:imprint/t:biblScope[@unit = 'page']"/>
            </xsl:if>
            <xsl:text>. </xsl:text>
            <!-- URL-Note -->
            <xsl:call-template name="process-url-note"/>
            <!-- Zotero-link -->
            <xsl:apply-templates select="." mode="zotero"/>
            <!-- Adding a bibliographic note if it exists -->
            <xsl:call-template name="insert-bibliographic-note"/>
        </div>
    </xsl:template>

    <!-- ========================= Template for Newspaper Articles (newspaperArticle) ========================= -->
    <xsl:template match="t:biblStruct[@type = 'newspaperArticle']">
        <div class="bibl-entry">
            <!-- Store 'corresp' attribute for potential linking -->
            <xsl:variable name="corresp" select="@corresp"/>
            <!-- Apply templates to 'analytic' (author, title) -->
            <xsl:apply-templates select="t:analytic"/>
            <xsl:call-template name="add-period-if-needed">
                <xsl:with-param name="text" select="string(t:analytic/t:title[@level = 'a'])"/>
            </xsl:call-template>
            <xsl:text> In: </xsl:text>
            <!-- Apply templates to 'monogr' (newspaper title) -->
            <xsl:apply-templates select="t:monogr"/>
            <xsl:text>, </xsl:text>
            <!-- Apply templates to publication place -->
            <xsl:apply-templates select="t:monogr/t:imprint/t:pubPlace"/>
            <xsl:text>, </xsl:text>
            <!-- Call format-date only if <date> exists -->
            <xsl:if test="t:monogr/t:imprint/t:date">
                <xsl:call-template name="format-date">
                    <xsl:with-param name="date" select="t:monogr/t:imprint/t:date"/>
                </xsl:call-template>
            </xsl:if>
            <!-- If page number exists, print it -->
            <xsl:if test="t:monogr/t:imprint/t:biblScope[@unit = 'page']">
                <xsl:text>, S. </xsl:text>
                <xsl:apply-templates select="t:monogr/t:imprint/t:biblScope[@unit = 'page']"/>
            </xsl:if>
            <xsl:text>. </xsl:text>
            <!-- URL Note -->
            <xsl:call-template name="process-url-note"/>
            <!-- Zotero Link -->
            <xsl:apply-templates select="." mode="zotero"/>
            <!-- Adding a bibliographic note if it exists -->
            <xsl:call-template name="insert-bibliographic-note"/>

        </div>
    </xsl:template>

    <!-- ========================= Template for Book Sections (bookSection) ========================= -->
    <xsl:template match="t:biblStruct[@type = 'bookSection']">
        <div class="bibl-entry">
            <xsl:variable name="corresp" select="@corresp"/>
            <!-- author and title of section -->
            <xsl:apply-templates select="t:analytic"/>
            <xsl:call-template name="add-period-if-needed">
                <xsl:with-param name="text" select="string(t:analytic/t:title[@level = 'a'])"/>
            </xsl:call-template>
            <xsl:text> In: </xsl:text>
            <!-- editor or author of book -->
            <xsl:choose>
                <xsl:when test="t:monogr/t:editor/t:name">
                    <xsl:text>hrsg. von </xsl:text>
                    <xsl:apply-templates select="t:monogr/t:editor/t:name"/>
                    <xsl:text>, </xsl:text>
                </xsl:when>
                <xsl:when test="t:monogr/t:editor">
                    <xsl:text>hrsg. von </xsl:text>
                    <xsl:for-each select="t:monogr/t:editor">
                        <xsl:apply-templates select="t:forename"/>
                        <xsl:text> </xsl:text>
                        <xsl:apply-templates select="t:surname"/>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>, </xsl:text>
                </xsl:when>
                <xsl:when test="t:monogr/t:author">
                    <xsl:for-each select="t:monogr/t:author">
                        <xsl:apply-templates select="t:forename"/>
                        <xsl:text> </xsl:text>
                        <xsl:apply-templates select="t:surname"/>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>, </xsl:text>
                </xsl:when>
            </xsl:choose>
            <!-- title of book -->
            <xsl:apply-templates select="t:monogr/t:title[@level = 'm']"/>
            <!-- volume (if any) -->
            <xsl:if test="t:monogr/t:imprint/t:biblScope[@unit = 'volume']">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="t:monogr/t:imprint/t:biblScope[@unit = 'volume']"/>
            </xsl:if>
            <xsl:text>. </xsl:text>
            <!-- pub place -->
            <xsl:apply-templates select="t:monogr/t:imprint/t:pubPlace"/>
            <!-- publisher -->
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="t:monogr/t:imprint/t:publisher"/>
            <!-- year -->
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:monogr/t:imprint/t:date"/>
            <xsl:if test="t:monogr/t:imprint/t:biblScope[@unit = 'page']">
                <xsl:text>, S. </xsl:text>
                <xsl:apply-templates select="t:monogr/t:imprint/t:biblScope[@unit = 'page']"/>
            </xsl:if>
            <xsl:text>. </xsl:text>
            <!-- URL -->
            <xsl:call-template name="process-url-note"/>
            <!-- Zotero-link -->
            <xsl:apply-templates select="." mode="zotero"/>
            <!-- Adding a bibliographic note if it exists -->
            <xsl:call-template name="insert-bibliographic-note"/>
        </div>
    </xsl:template>

    <!-- ========================= Template for Monographs (book) ========================= -->
    <xsl:template match="t:biblStruct[not(@type)] | t:biblStruct[@type = 'book']">
        <div class="bibl-entry">
            <!-- Stores the 'corresp' attribute value for potential linking -->
            <xsl:variable name="corresp" select="@corresp"/>
            <!-- Apply templates to the 'monogr' part (book title, etc.) -->
            <xsl:apply-templates select="t:monogr"/>
            <xsl:text>. </xsl:text>
            <!-- Apply templates to the publication place -->
            <xsl:apply-templates select="t:monogr/t:imprint/t:pubPlace"/>
            <xsl:text>: </xsl:text>
            <!-- Apply templates to the publisher -->
            <xsl:apply-templates select="t:monogr/t:imprint/t:publisher"/>
            <xsl:text> </xsl:text>
            <!-- Apply templates to the publication date -->
            <xsl:apply-templates select="t:monogr/t:imprint/t:date"/>
            <xsl:text>. </xsl:text>
            <!-- Check if series information is available -->
            <xsl:if test="t:series/t:title[@level = 's']">
                <xsl:text> (= </xsl:text>
                <!-- Apply templates to the series title -->
                <xsl:apply-templates select="t:series/t:title[@level = 's']"/>
                <!-- Check if series volume information is available -->
                <xsl:if test="t:series/t:biblScope[@unit = 'volume']">
                    <xsl:text>, </xsl:text>
                    <!-- Apply templates to the series volume -->
                    <xsl:apply-templates select="t:series/t:biblScope[@unit = 'volume']"/>
                </xsl:if>
                <xsl:text>)</xsl:text>
            </xsl:if>
            <!-- URL-Note -->
            <xsl:call-template name="process-url-note"/>
            <!-- Zotero-link -->
            <xsl:apply-templates select="." mode="zotero"/>
            <!-- Adding a bibliographic note if it exists -->
            <xsl:call-template name="insert-bibliographic-note"/>
        </div>
    </xsl:template>

    <!-- ========================= Processing of Articles and Book Chapters ========================= -->
    <xsl:template match="t:analytic">
        <!-- Apply templates to the author(s) -->
        <xsl:apply-templates select="t:author"/>
        <xsl:text>: </xsl:text>
        <!-- Apply templates to the title of the article or chapter -->
        <xsl:apply-templates select="t:title[@level = 'a']"/>
    </xsl:template>

    <!-- ========================= Formatting Titles (italic) ========================= -->
    <xsl:template match="t:title">
        <span class="bibl-title">
            <i>
                <xsl:apply-templates/>
            </i>
        </span>
    </xsl:template>

    <!-- ========================= Formatting Authors ========================= -->
    <xsl:template match="t:author">
        <!-- Apply templates to the surname -->
        <xsl:apply-templates select="t:surname"/>
        <xsl:text>, </xsl:text>
        <!-- Apply templates to the forename -->
        <xsl:apply-templates select="t:forename"/>
        <!-- Add a semicolon if it's not the last author -->
        <xsl:if test="position() != last()">
            <xsl:text>; </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- ========================= Monograph Title Formatting ========================= -->
    <xsl:template match="t:monogr/t:title[@level = 'm']">
        <span class="bibl-title">
            <i>
                <xsl:apply-templates/>
            </i>
        </span>
    </xsl:template>

    <!-- ========================= Journal Title Formatting ========================= -->
    <xsl:template match="t:monogr/t:title[@level = 'j']">
        <span class="bibl-title">
            <i>
                <xsl:apply-templates/>
            </i>
        </span>
    </xsl:template>

    <!-- ========================= Editor Formatting ========================= -->
    <xsl:template name="format-editor">
        <xsl:param name="select" as="element()*"/>
        <xsl:param name="context" as="xs:string"/>
        <xsl:if test="$select">
            <xsl:choose>
                <xsl:when test="$select[1]/t:forename and $select[1]/t:surname">
                    <xsl:choose>
                        <xsl:when test="$context = 'journal'">
                            <xsl:text>, hrsg. von </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>hrsg. von </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="$select">
                        <xsl:apply-templates select="t:forename"/>
                        <xsl:text> </xsl:text>
                        <xsl:apply-templates select="t:surname"/>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$select[1]/t:name">
                    <xsl:choose>
                        <xsl:when test="$context = 'journal'">
                            <xsl:text>, hrsg. </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>hrsg. </xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="$select">
                        <xsl:value-of select="t:name"/>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- ========================= Template for Monogr within Book Sections ========================= -->
    <xsl:template match="t:biblStruct[@type = 'bookSection']/t:monogr">
        <!-- Format editor if present -->
        <xsl:call-template name="format-editor">
            <xsl:with-param name="select" select="t:editor"/>
            <xsl:with-param name="context" select="'bookSection'"/>
        </xsl:call-template>
        <xsl:text>, </xsl:text>
        <!-- Space after editor -->
        <!-- Book title -->
        <xsl:apply-templates select="t:title[@level = 'm']"/>
        <!-- Volume information -->
        <xsl:if test="t:imprint/t:biblScope[@unit = 'volume']">
            <xsl:text>, Bd. </xsl:text>
            <xsl:apply-templates select="t:imprint/t:biblScope[@unit = 'volume']"/>
        </xsl:if>
        <!-- Publication place -->
        <xsl:if test="t:imprint/t:pubPlace">
            <xsl:text>. </xsl:text>
            <xsl:apply-templates select="t:imprint/t:pubPlace"/>
        </xsl:if>
        <!-- Publisher -->
        <xsl:if test="t:imprint/t:publisher">
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="t:imprint/t:publisher"/>
        </xsl:if>
        <!-- Publication date -->
        <xsl:if test="t:imprint/t:date">
            <xsl:text> </xsl:text>
            <xsl:call-template name="format-date"/>
        </xsl:if>
    </xsl:template>

    <!-- ========================= General Template for Monogr ========================= -->
    <xsl:template match="t:monogr">
        <!-- Add author information if it's a monograph (not a journal article or book section) -->
        <xsl:if
            test="t:author and not(ancestor::t:biblStruct[@type = 'journalArticle'] or ancestor::t:biblStruct[@type = 'bookSection'])">
            <xsl:apply-templates select="t:author"/>
            <xsl:text>: </xsl:text>
        </xsl:if>
        <!-- Apply templates to the title -->
        <xsl:apply-templates select="t:title"/>
        <!-- Volume and issue information for journal articles -->
        <xsl:if test="ancestor::t:biblStruct[@type = 'journalArticle']">
            <xsl:if test="t:imprint/t:biblScope[@unit = 'volume']">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="t:imprint/t:biblScope[@unit = 'volume']"/>
            </xsl:if>
            <xsl:if test="t:imprint/t:biblScope[@unit = 'issue']">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="t:imprint/t:biblScope[@unit = 'issue']"/>
            </xsl:if>
        </xsl:if>
        <!-- Volume information for monographs -->
        <xsl:if
            test="t:imprint/t:biblScope[@unit = 'volume'] and ancestor::t:biblStruct[not(@type) or @type = 'book']">
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:imprint/t:biblScope[@unit = 'volume']"/>
        </xsl:if>
        <!-- Series information -->
        <xsl:if test="t:series">
            <xsl:text>. (= </xsl:text>
            <xsl:apply-templates select="t:series/t:title"/>
            <xsl:if test="t:series/t:biblScope[@unit = 'volume']">
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="t:series/t:biblScope[@unit = 'volume']"/>
            </xsl:if>
            <xsl:text>)</xsl:text>
        </xsl:if>
        <!-- Date for journal articles -->
        <xsl:if test="t:imprint/t:date and ancestor::t:biblStruct[@type = 'journalArticle']">
            <xsl:text> (</xsl:text>
            <xsl:call-template name="format-date">
                <xsl:with-param name="date" select="t:imprint/t:date"/>
            </xsl:call-template>
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- imprint information is handled within the specific biblStruct templates. -->
    <xsl:template match="t:imprint"/>

</xsl:stylesheet>
