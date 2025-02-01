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
  
  Example output formats:

  1. Book:
     Doe, John: Example Book Title. Berlin: Example Publisher 2020.

  2. Book Section:
     Doe, John: Example Chapter Title. In: Smith, Jane, The Study of Languages. 
     London: Example Publisher, p. 123–134.

  3. Book Section (if `t:biblScope[@unit='volume']` is used; multi-volume work):
     Doe, John: Example Chapter Title. In: ed. by Brown, Alice, The Great Anthology of Literature, vol. 3. 
     Mannheim: Example Press, p. 76–87.

  4. Journal Article:
     Doe, John: Example Article Title. In: Example Journal, ed. by Smith, Jane, vol. 5 (2023).

  4. Newspaper Article:
     Doe, John: Example News Article Title. In: Example Newspaper: Morning Edition, 
     New York, 10. July 2022, p. 4.


  If available, the following elements are appended to each citation:  
  [Digitalisat] Zotero Icon <small>Additional bibliographic notes.</small>


  sgoettel, 2025.
===============================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:t="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="t">

    <!-- Output Method and Encoding -->
    <xsl:output method="html" media-type="text/html" cdata-section-elements="script style"
        indent="no" encoding="utf-8"/>
    
    <!-- Suppress teiHeader output -->
    <xsl:template match="t:teiHeader"/>

    <!-- ========================= Template for URL Notes ========================= -->
    <xsl:template match="t:note[@type = 'url']">
        <xsl:text>[</xsl:text>
        <a href="{text()}" target="_blank">Digitalisat</a>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <!-- ========================= Named Template for Date Formatting ========================= -->
<xsl:template name="format-date">
    <xsl:param name="date" select="t:monogr/t:imprint/t:date"/>

    <xsl:choose>
        <!-- If the date is in the expected format YYYY-MM-DD -->
        <xsl:when test="string-length($date) = 10 and substring($date, 5, 1) = '-' and substring($date, 8, 1) = '-'">
            
            <!-- Extract year, month, and day -->
            <xsl:variable name="year" select="substring($date, 1, 4)"/>
            <xsl:variable name="month" select="number(substring($date, 6, 2))"/>
            <xsl:variable name="day" select="number(substring($date, 9, 2))"/>
            <!-- `number()` automatically removes leading zeros from single-digit days -->

            <!-- Lookup table for month names -->
            <xsl:variable name="month-names" select="'Januar Februar März April Mai Juni Juli August September Oktober November Dezember'"/>
            
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

    <!-- ========================= Template for Journal Articles (journalArticle) ========================= -->
    <xsl:template match="t:biblStruct[@type = 'journalArticle']">
        <div class="bibl-entry">
        <!-- Stores the 'corresp' attribute value for potential linking -->
        <xsl:variable name="corresp" select="@corresp"/>
        <!-- Apply templates to the 'analytic' part (author and title of the article) -->
        <xsl:apply-templates select="t:analytic"/>
        <xsl:text>. In: </xsl:text>
        <!-- Journal Title -->
        <xsl:apply-templates select="t:monogr/t:title[@level = 'j']"/>
        <!-- Editor (if any) -->
        <xsl:if test="t:monogr/t:editor">
            <xsl:text>, hrsg. von </xsl:text>
            <xsl:apply-templates select="t:monogr/t:editor"/>
        </xsl:if>
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
        <!-- URL-Note -->
        <xsl:call-template name="process-url-note"/>
        <!-- Zotero-link -->
        <xsl:apply-templates select="." mode="zotero"/>
        <!-- Adding a bibliographic note if it exists -->
        <xsl:if test="t:note[@type = 'bibliographic']">
            <xsl:text> </xsl:text>
            <span style="font-size: smaller;">
                <xsl:apply-templates select="t:note[@type = 'bibliographic']"/>
            </span>
        </xsl:if>
        </div>
    </xsl:template>

    <!-- ========================= Template for Newspaper Articles (newspaperArticle) ========================= -->
    <xsl:template match="t:biblStruct[@type = 'newspaperArticle']">
        <div class="bibl-entry">
        <!-- Store 'corresp' attribute for potential linking -->
        <xsl:variable name="corresp" select="@corresp"/>
        <!-- Apply templates to 'analytic' (author, title) -->
        <xsl:apply-templates select="t:analytic"/>
        <xsl:text>. In: </xsl:text>
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
        <!-- Add bibliographic note if available -->
        <xsl:if test="t:note[@type = 'bibliographic']">
            <xsl:text> </xsl:text>
            <span style="font-size: smaller;">
                <xsl:apply-templates select="t:note[@type = 'bibliographic']"/>
            </span>
        </xsl:if>
        </div>
    </xsl:template>

    <!-- ========================= Template for Book Sections (bookSection) ========================= -->
    <xsl:template match="t:biblStruct[@type = 'bookSection']">
        <div class="bibl-entry">
        <!-- Stores the 'corresp' attribute value for potential linking -->
        <xsl:variable name="corresp" select="@corresp"/>
        <!-- Apply templates to the 'analytic' part (author and title of the chapter) -->
        <xsl:apply-templates select="t:analytic"/>
        <xsl:text>. In: </xsl:text>
        <!-- Apply templates to the 'monogr' part (book title, editor, etc.) -->
        <xsl:apply-templates select="t:monogr"/>
        <!-- Check if page information is available -->
        <xsl:if test="t:monogr/t:imprint/t:biblScope[@unit = 'page']">
            <xsl:text>, S. </xsl:text>
            <!-- Apply templates to the page number -->
            <xsl:apply-templates select="t:monogr/t:imprint/t:biblScope[@unit = 'page']"/>
        </xsl:if>
        <xsl:text>. </xsl:text>
        <!-- URL-Note -->
        <xsl:call-template name="process-url-note"/>
        <!-- Zotero-link -->
        <xsl:apply-templates select="." mode="zotero"/>
        <!-- Adding a bibliographic note if it exists -->
        <xsl:if test="t:note[@type = 'bibliographic']">
            <xsl:text> </xsl:text>
            <span style="font-size: smaller;">
                <xsl:apply-templates select="t:note[@type = 'bibliographic']"/>
            </span>
        </xsl:if>
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
        <xsl:if test="t:note[@type = 'bibliographic']">
            <xsl:text> </xsl:text>
            <span style="font-size: smaller;">
                <xsl:apply-templates select="t:note[@type = 'bibliographic']"/>
            </span>
        </xsl:if>
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

    <!-- ========================= Editor Formatting for Monographs ========================= -->
    <xsl:template match="t:monogr/t:editor">
        <!-- Apply templates to the forename -->
        <xsl:apply-templates select="t:forename"/>
        <xsl:text> </xsl:text>
        <!-- Apply templates to the surname -->
        <xsl:apply-templates select="t:surname"/>
        <!-- Add a comma and space if it's NOT the last editor -->
        <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- ========================= Template for Monogr within Book Sections ========================= -->
    <xsl:template match="t:biblStruct[@type = 'bookSection']/t:monogr">
        <xsl:choose>
            <!-- If the monogr has authors, process them -->
            <xsl:when test="t:author">
                <xsl:apply-templates select="t:author"/>
            </xsl:when>
            <!-- If the monogr has an editor with a 'name' element, process it -->
            <xsl:when test="t:editor/t:name">
                <xsl:apply-templates select="t:editor/t:name"/>
            </xsl:when>
            <!-- If the monogr has an editor (with forename and surname), format as editor -->
            <xsl:when test="t:editor">
                <xsl:text>hrsg. von </xsl:text>
                <xsl:apply-templates select="t:editor"/>
            </xsl:when>
        </xsl:choose>
        <xsl:text>, </xsl:text>
        <!-- Apply templates to the title of the book -->
        <xsl:apply-templates select="t:title[@level = 'm']"/>

        <!-- Check if volume information is available -->
        <xsl:if test="t:imprint/t:biblScope[@unit = 'volume']">
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="t:imprint/t:biblScope[@unit = 'volume']"/>
        </xsl:if>

        <!-- Add publication place if available -->
        <xsl:if test="t:imprint/t:pubPlace">
            <xsl:text>. </xsl:text>
            <xsl:apply-templates select="t:imprint/t:pubPlace"/>
        </xsl:if>
        <!-- Add publisher if available -->
        <xsl:if test="t:imprint/t:publisher">
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="t:imprint/t:publisher"/>
        </xsl:if>
        <!-- Add publication date if available -->
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

        <!-- Editor information specifically for journal articles -->
        <xsl:if test="ancestor::t:biblStruct[@type = 'journalArticle']">
            <xsl:choose>
                <!-- Standard case: editor with forename and surname -->
                <xsl:when test="t:editor/t:forename and t:editor/t:surname">
                    <xsl:text>, hrsg. von </xsl:text>
                    <xsl:apply-templates select="t:editor"/>
                </xsl:when>
                <!-- Special case: editor with a 'name' element -->
                <xsl:when test="t:editor/t:name">
                    <xsl:text>, hrsg. von </xsl:text>
                    <xsl:value-of select="t:editor/t:name"/>
                </xsl:when>
                <!-- If no editor information is available, do nothing -->
            </xsl:choose>
        </xsl:if>

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
