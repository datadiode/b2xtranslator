<?xml version="1.0" encoding="UTF-8"?>
<!--
 * Copyright (c) 2006, Clever Age
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Clever Age nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:ooc="urn:odf-converter"
  exclude-result-prefixes="office text table fo style draw ooc">


  <!-- Specifies that measurement of table properties are interpreted as twentieths of a point -->
  <xsl:variable name="type">dxa</xsl:variable>

  <!-- 
  *************************************************************************
  MATCHING TEMPLATES
  *************************************************************************
  -->

  <!-- Tables -->
  <xsl:template match="table:table">
    <!-- warn if subtable -->
    <xsl:if test="@table:is-sub-table='true' ">
      <xsl:message terminate="no">translation.odf2oox.subtableBordersPadding</xsl:message>
    </xsl:if>
    <!-- warn if consecutive tables -->
    <xsl:if test="preceding-sibling::table:table[not(@table:is-sub-table='true')] and not(@table:is-sub-table='true')">
      <xsl:message terminate="no">translation.odf2oox.consecutiveTables</xsl:message>
    </xsl:if>
    <w:tbl>
      <xsl:call-template name="MarkMasterPage"/>
      <w:tblPr>
        <xsl:choose>
          <xsl:when test="@table:is-sub-table='true'">
            <xsl:call-template name="InsertSubTableProperties"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="InsertTableProperties"/>
          </xsl:otherwise>
        </xsl:choose>
      </w:tblPr>
      <xsl:call-template name="InsertTblGrid"/>
      <!-- Header rows not handled the same way in OOX -->
      <xsl:if test="table:table-header-rows/table:table-row">
        <xsl:message terminate="no">translation.odf2oox.tableHeaderRepeated</xsl:message>
      </xsl:if>
      <xsl:if test="count(table:table-header-rows/table:table-row) &gt; 1">
        <xsl:message terminate="no">translation.odf2oox.tableHeaderRows</xsl:message>
      </xsl:if>
      <xsl:apply-templates select="table:table-header-rows/table:table-row | table:table-row"/>
    </w:tbl>
    <xsl:call-template name="ManageSectionsInTable"/>
  </xsl:template>

  <!-- table rows -->
  <xsl:template match="table:table-row">
    <xsl:call-template name="InsertRow">
      <xsl:with-param name="number" select="@table:number-rows-repeated"/>
    </xsl:call-template>
  </xsl:template>

  <!-- 
  Summary: Converts table cells
  Author: Clever Age
  Modified: makz (DIaLOGIKa)
  Date: 26.10.2007
  -->
  <xsl:template match="table:table-cell">
    <xsl:param name="isFirstRow"/>
    <w:tc>
      <w:tcPr>
        <xsl:call-template name="InsertCellProperties">
          <xsl:with-param name="cellStyleName" select="@table:style-name"/>
          <xsl:with-param name="rowStyleName" select="parent::table:table-row/@table:style-name" />
          <xsl:with-param name="tableStyleName" select="ancestor::table:table[@table:style-name][1]/@table:style-name" />
        </xsl:call-template>
      </w:tcPr>
      <xsl:apply-templates>
        <xsl:with-param name="isFirstRow" select="$isFirstRow"/>
      </xsl:apply-templates>
      <!-- avoid crash -->
      <xsl:if test="child::node()[last()][self::table:table]">
        <xsl:call-template name="InsertEmptyParagraph"/>
      </xsl:if>
    </w:tc>
  </xsl:template>

  <!-- 
  Summary: Converts covered table cells
  Author: makz (DIaLOGIKa)
  Date: 13.11.2007
  -->
  <xsl:template match="table:covered-table-cell">

    <xsl:variable name="myPos" select="position()" />

    <!-- 
    Insert covered cells only if the cell belongs to a vertical merge.
    Covered cells of horizontal merges shell not be converted.
    -->
    <xsl:variable name="isPartOfHorizontalMerge">
      <xsl:for-each select="preceding-sibling::table:table-cell">
        <!-- context switch foreach to get position() -->
        <xsl:variable name="cellPos" select="position()" />
        <xsl:if test="@table:number-columns-spanned">
          <xsl:variable name="colspan" select="@table:number-columns-spanned" />
          <xsl:if test="($myPos - $cellPos &lt; $colspan) or ($myPos - $cellPos = $colspan)">
            <xsl:text>true</xsl:text>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:if test="not(contains($isPartOfHorizontalMerge, 'true'))">
      <w:tc>
        <w:tcPr>
          <xsl:call-template name="InsertCellProperties">
            <!-- 
            call with the style of the cell in the row above, 
            because covered cells don't have an own style
            -->
            <xsl:with-param name="cellStyleName">
              <!--
              Context swticth go get into the row above -->
              <xsl:for-each select="parent::table:table-row">
                <xsl:value-of select="preceding-sibling::table:table-row[1]/table:table-cell[number($myPos)]/@table:style-name"/>
              </xsl:for-each>
            </xsl:with-param>
            <xsl:with-param name="rowStyleName" select="parent::table:table-row/@table:style-name" />
            <xsl:with-param name="tableStyleName" select="ancestor::table:table[@table:style-name][1]/@table:style-name" />
          </xsl:call-template>
        </w:tcPr>
        <w:p />
      </w:tc>
    </xsl:if>
  </xsl:template>

  <!-- 
  *************************************************************************
  CALLED TEMPLATES
  *************************************************************************
  -->

  <!-- Inserts table properties -->
  <xsl:template name="InsertTableProperties">

    <w:tblStyle w:val="{@table:style-name}"/>

    <xsl:variable name="tableProp" select="key('automatic-styles', @table:style-name)/style:table-properties" />

    <!-- report lost attributes -->
    <xsl:if test="$tableProp/@fo:keep-with-next">
      <xsl:message terminate="no">translation.odf2oox.tableTogetherWithParagraph</xsl:message>
    </xsl:if>
    <xsl:if test="not($tableProp/@style:may-break-between-rows='true')">
      <xsl:message terminate="no">translation.odf2oox.unsplitableTable</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:background-image">
      <xsl:message terminate="no">translation.odf2oox.tableBgImage</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:shadow">
      <xsl:message terminate="no">translation.odf2oox.tableShadow</xsl:message>
    </xsl:if>

    <!-- table width -->
    <xsl:choose>
      <xsl:when test="$tableProp/@style:rel-width">
        <w:tblW w:type="pct">
          <xsl:attribute name="w:w">
            <xsl:value-of select="50 * number(substring-before($tableProp/@style:rel-width, '%'))"/>
          </xsl:attribute>
        </w:tblW>
      </xsl:when>
      <xsl:when test="$tableProp/@style:width">
        <w:tblW w:type="{$type}">
          <xsl:attribute name="w:w">
            <xsl:value-of select="ooc:TwipsFromMeasuredUnit($tableProp/@style:width)" />
          </xsl:attribute>
        </w:tblW>
      </xsl:when>
      <xsl:otherwise>
        <!-- default value if no width specified : 100% of width -->
        <w:tblW w:w="5000" w:type="pct"/>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$tableProp/@table:align">
      <xsl:choose>
        <xsl:when test="$tableProp/@table:align = 'margins'">
          <!--User agents that do not support the "margins" value, may treat this value as "left".-->
          <xsl:message terminate="no">translation.odf2oox.tableManualAlignment</xsl:message>
          <w:jc w:val="left"/>
        </xsl:when>
        <xsl:otherwise>
          <w:jc w:val="{$tableProp/@table:align}"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="not($tableProp/@table:align ='center')">
      <xsl:call-template name="InsertTableIndentElement"/>
    </xsl:if>

    <!--table background-->
    <xsl:if test="$tableProp/@fo:background-color">
      <xsl:choose>
        <xsl:when test="$tableProp/@fo:background-color != 'transparent' ">
          <w:shd w:val="clear" w:color="auto"
            w:fill="{substring($tableProp/@fo:background-color, 2, string-length($tableProp/@fo:background-color) -1)}"
          />
        </xsl:when>
      </xsl:choose>
    </xsl:if>

    <!-- Default layout algorithm in ODF is "fixed". -->
    <w:tblLayout w:type="fixed"/>

    <!-- default margins -->
    <w:tblCellMar>
      <xsl:for-each select="descendant::table:table-cell[1]">
        <xsl:call-template name="InsertCellMargins">
          <xsl:with-param name="cellProp" select="key('automatic-styles', @table:style-name)/style:table-cell-properties"/>
          <xsl:with-param name="defaultMargin">true</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </w:tblCellMar>
  </xsl:template>

  <!-- Inserts a row -->
  <xsl:template name="InsertRow">
    <xsl:param name="number"/>
    <w:tr>
      <xsl:if
        test="key('automatic-styles',child::table:table-cell/@table:style-name)/style:table-cell-properties/@fo:wrap-option='no-wrap'">
        <!-- Override layout algorithm -->
        <w:tblPrEx>
          <w:tblLayout w:type="autofit"/>
        </w:tblPrEx>
      </xsl:if>
      <w:trPr>
        <xsl:call-template name="InsertRowProperties"/>
      </w:trPr>
      <xsl:apply-templates select="*[position() &lt; 64]">
        <xsl:with-param name="isFirstRow">
          <xsl:if
            test="key('automatic-styles', ancestor::table:table[1]/@table:style-name)/style:table-properties/@fo:break-before = 'page'
            or key('automatic-styles', ancestor::table:table[1]/@table:style-name)/@style:master-page-name != ''">
            <xsl:value-of
              select="boolean((@table:number-rows-repeated = $number) and (preceding-sibling::*[1][self::table:table-column or self::table:table-columns] or not(preceding-sibling::node())))"
            />
          </xsl:if>
        </xsl:with-param>
      </xsl:apply-templates>
      <xsl:if test="*[position() &gt;= 64]">
        <xsl:message terminate="no">translation.odf2oox.tableWith64Columns</xsl:message>
      </xsl:if>
    </w:tr>
    <xsl:if test="$number > 1">
      <xsl:call-template name="InsertRow">
        <xsl:with-param name="number" select="$number - 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Inserts row properties -->
  <xsl:template name="InsertRowProperties">
    <!-- report lost attributes -->
    <xsl:if
      test="key('automatic-styles',@table:style-name)/style:table-row-properties/@style:background-image">
      <xsl:message terminate="no">translation.odf2oox.rowBgImage</xsl:message>
    </xsl:if>

    <xsl:call-template name="InsertRowHeaderMark"/>
    <xsl:call-template name="InsertRowHeight"/>
    <xsl:call-template name="InsertRowKeepTogether"/>
  </xsl:template>

  <!-- Inserts row header mark -->
  <xsl:template name="InsertRowHeaderMark">
    <xsl:if test="parent::table:table-header-rows">
      <w:tblHeader/>
    </xsl:if>
  </xsl:template>

  <!-- Inserts row height -->
  <xsl:template name="InsertRowHeight">
    <xsl:if test="@table:style-name">
      <xsl:variable name="rowProp"
        select="key('automatic-styles',@table:style-name)/style:table-row-properties"/>
      <xsl:variable name="rowHeight">
        <xsl:choose>
          <xsl:when test="$rowProp[@style:row-height]">
            <xsl:value-of select="$rowProp/@style:row-height"/>
          </xsl:when>
          <xsl:when test="$rowProp[@style:min-row-height]">
            <xsl:value-of select="$rowProp/@style:min-row-height"/>
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <w:trHeight>
        <!-- get number value of height to check if row height is not negative. -->
        <xsl:variable name="checkRowHeight">
          <xsl:call-template name="GetValue">
            <xsl:with-param name="length" select="$rowHeight"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:attribute name="w:val">
          <xsl:choose>
            <xsl:when test="number($checkRowHeight) &lt; 0">0</xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="ooc:TwipsFromMeasuredUnit($rowHeight)" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="w:hRule">
          <xsl:choose>
            <xsl:when test="$rowProp[@style:row-height]">
              <xsl:value-of select="'exact'"/>
            </xsl:when>
            <xsl:when test="$rowProp[@style:min-row-height]">
              <xsl:value-of select="'atLeast'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'auto'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </w:trHeight>
    </xsl:if>
  </xsl:template>

  <!--Inserts keep together-->
  <xsl:template name="InsertRowKeepTogether">
    <xsl:if
      test="key('automatic-styles', @table:style-name)/style:table-row-properties/@style:keep-together = 'false'
    or key('automatic-styles', ancestor::table:table[@table:style-name][1]/@table:style-name)/style:table-properties/@style:may-break-between-rows='false'">
      <w:cantSplit/>
    </xsl:if>
  </xsl:template>

  <!-- In case the table is a subtable. Unherits a few properties of table it belongs to. -->
  <xsl:template name="InsertSubTableProperties">
    <xsl:variable name="tableStyleName" select="ancestor::table:table[1][not(@table:is-sub-table='true')]/@table:style-name"/>
    
    <w:tblStyle w:val="{$tableStyleName}"/>
    <xsl:variable name="tableProp" select="key('automatic-styles', $tableStyleName)/style:table-properties"/>

    <!-- report lost attributes -->
    <xsl:if test="$tableProp/@fo:keep-with-next">
      <xsl:message terminate="no">translation.odf2oox.tableTogetherWithParagraph</xsl:message>
    </xsl:if>
    <xsl:if test="not($tableProp/@style:may-break-between-rows='true')">
      <xsl:message terminate="no">translation.odf2oox.unsplitableTable</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:background-image">
      <xsl:message terminate="no">translation.odf2oox.tableBgImage</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:shadow">
      <xsl:message terminate="no">translation.odf2oox.tableShadow</xsl:message>
    </xsl:if>

    <w:tblW>
      <xsl:attribute name="w:type">
        <xsl:choose>
          <xsl:when test="$tableProp/@style:rel-width">pct</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$type"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="w:w">
        <xsl:for-each select="ancestor::table:table-cell[1]">

          <!--<xsl:call-template name="GetCellWidth"/>-->

          <xsl:call-template name="GetTotalCellWidth">
            <xsl:with-param name="colPos" select="1" />
            <xsl:with-param name="colEndPos" select="1 + @table:number-columns-spanned" />
            <xsl:with-param name="columns" select="ancestor::table:table/table:table-column | ancestor::table:table/table:table-columns/table:table-column" />
          </xsl:call-template>

        </xsl:for-each>
      </xsl:attribute>
    </w:tblW>

    <!--table background-->
    <xsl:if test="$tableProp/@fo:background-color">
      <xsl:choose>
        <xsl:when test="$tableProp/@fo:background-color != 'transparent' ">
          <w:shd w:val="clear" w:color="auto" w:fill="{substring($tableProp/@fo:background-color, 2, string-length($tableProp/@fo:background-color) -1)}" />
        </xsl:when>
      </xsl:choose>
    </xsl:if>

    <!-- Default layout algorithm in ODF is "fixed". -->
    <w:tblLayout w:type="fixed"/>
  </xsl:template>

  <!-- 
  Insert the table indent if margin-left defined, 
  or if cell-padding greater than 0. 
  -->
  <xsl:template name="InsertTableIndentElement">

    <xsl:variable name="marginLeft" select="ooc:TwipsFromMeasuredUnit(key('automatic-styles', @table:style-name)/style:table-properties/@fo:margin-left)" />

    <xsl:variable name="padding">
      <xsl:choose>
        <xsl:when test="key('automatic-styles', descendant::table:table-cell[1][not(@table:is-sub-table = 'true')]/@table:style-name)/style:table-cell-properties[@fo:padding and @fo:padding != 'none'] and not(ancestor::table:table)">
          <xsl:call-template name="twips-measure">
            <xsl:with-param name="length">
              <xsl:value-of select="key('automatic-styles', descendant::table:table-cell[1][not(@table:is-sub-table = 'true')]/@table:style-name)/style:table-cell-properties/@fo:padding" />
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="key('automatic-styles', descendant::table:table-cell[1][not(@table:is-sub-table = 'true')]/@table:style-name)/style:table-cell-properties[@fo:padding-left and @fo:padding-left != 'none'] and not(ancestor::table:table)">
          <xsl:call-template name="twips-measure">
            <xsl:with-param name="length">
              <xsl:value-of select="key('automatic-styles', descendant::table:table-cell[1][not(@table:is-sub-table = 'true')]/@table:style-name)/style:table-cell-properties/@fo:padding-left" />
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <w:tblInd w:type="{$type}" w:w="{$marginLeft + $padding}" />
    
  </xsl:template>

  <!-- Inserts a table grid -->
  <xsl:template name="InsertTblGrid">
    <w:tblGrid>
      <!-- table:table-column may be directly below table:table or within a table:table-columns container -->
      <xsl:for-each select="table:table-columns/table:table-column | table:table-column">
        <xsl:call-template name="InsertGridCol">
          <xsl:with-param name="width">
            <xsl:call-template name="ComputeColumnWidth"/>
          </xsl:with-param>
          <xsl:with-param name="number" select="@table:number-columns-repeated"/>
        </xsl:call-template>
      </xsl:for-each>
    </w:tblGrid>
  </xsl:template>

  <!-- Inserts a gridCol -->
  <xsl:template name="InsertGridCol">
    <xsl:param name="width"/>
    <xsl:param name="number"/>
    <xsl:variable name="widthVal">
      <xsl:call-template name="GetValue">
        <xsl:with-param name="length" select="$width"/>
      </xsl:call-template>
    </xsl:variable>
    <w:gridCol>
      <xsl:attribute name="w:w">
        <xsl:choose>
          <xsl:when test="number($widthVal)">
            <xsl:value-of select="ooc:TwipsFromMeasuredUnit($width)" />
          </xsl:when>
          <!-- WARNING : 0 should be the default value, but Word 2007 cannot compute layout properly.
          Another solution would be to return an empty string, but  an empty tblGrid does not pass validation (although it is permitted by OOX spec) -->
          <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </w:gridCol>
    <xsl:if test="$number > 1">
      <xsl:call-template name="InsertGridCol">
        <xsl:with-param name="width" select="$width"/>
        <xsl:with-param name="number" select="$number - 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- returns a measured value, a twips value, or a percentage value. Context must be table:column -->
  <xsl:template name="ComputeColumnWidth">

    <xsl:variable name="tablePercentVal" select="substring-before(key('automatic-styles',parent::table:table/@table:style-name)/style:table-properties/@style:rel-width,'%')" />
    
    <xsl:choose>
      <xsl:when test="key('automatic-styles',@table:style-name)/style:table-column-properties/@style:column-width and $tablePercentVal = '' ">
        <xsl:value-of select="key('automatic-styles',@table:style-name)/style:table-column-properties/@style:column-width" />
      </xsl:when>
      <xsl:otherwise>
        <!-- compute relatives width -->
        <xsl:variable name="relWidth"
          select="substring-before(key('automatic-styles',@table:style-name)/style:table-column-properties/@style:rel-column-width, '*')"/>
        <xsl:variable name="totRelWidth">
          <xsl:call-template name="ComputeTotalRelativeWidth">
            <xsl:with-param name="columns" select="parent::node()/table:table-column | parent::node()/table:table-columns/table:table-column"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <!-- when table is expressed in percentage -->
          <xsl:when test="$tablePercentVal != '' ">
            <xsl:value-of select="round(50 * $relWidth * 100 div $totRelWidth)"/>
          </xsl:when>
          <!-- when a width is available for the column -->
          <xsl:when test="ancestor::table:table[1]/@style:width">
            <xsl:value-of select="round(ancestor::table:table[1]/@style:width * $relWidth div $totRelWidth)"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- try to find the good width -->
            <xsl:variable name="pageWidth">
              <!-- TODO : find a better matching page width -->
              <xsl:for-each select="document('styles.xml')">
                <xsl:variable name="pageW" select="ooc:TwipsFromMeasuredUnit(key('page-layouts', $default-master-style/@style:page-layout-name)[1]/style:page-layout-properties/@fo:page-width)" />
                <xsl:variable name="pageMarginL" select="ooc:TwipsFromMeasuredUnit(key('page-layouts', $default-master-style/@style:page-layout-name)[1]/style:page-layout-properties/@fo:margin-left)" />
                <xsl:variable name="pageMarginR" select="ooc:TwipsFromMeasuredUnit(key('page-layouts', $default-master-style/@style:page-layout-name)[1]/style:page-layout-properties/@fo:margin-right)" />

                <xsl:value-of select="$pageW - $pageMarginR - $pageMarginL"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="round($pageWidth * $relWidth div $totRelWidth)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="ComputeTotalRelativeWidth">
    <xsl:param name="totRelWidth" select="0"/>
    <xsl:param name="columns"/>
    <xsl:choose>
      <xsl:when test="count($columns) &gt; 0">
        <xsl:variable name="addedWidth">
          <xsl:for-each select="$columns[1]">
            <xsl:variable name="repeat">
              <xsl:choose>
                <xsl:when test="@table:number-columns-repeated">
                  <xsl:value-of select="@table:number-columns-repeated"/>
                </xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="relWidth" select="substring-before(key('automatic-styles',@table:style-name)/style:table-column-properties/@style:rel-column-width,'*')" />
            
            <xsl:value-of select="$repeat * $relWidth"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="ComputeTotalRelativeWidth">
          <xsl:with-param name="columns" select="$columns[position() &gt; 1]"/>
          <xsl:with-param name="totRelWidth" select="$totRelWidth + $addedWidth"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$totRelWidth"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!--
  Summary:  Inserts the properties of a w:tc
  Author:   CleverAge
  Modified: makz (DIaLOGIKa)
  Params:   cellStyleName: The name of the cell's style
            rowStyleName: The name of the parent row's style
            tableStyleName: The name of the parent table's style
  -->
  <xsl:template name="InsertCellProperties">
    <xsl:param name="cellStyleName" />
    <xsl:param name="rowStyleName" />
    <xsl:param name="tableStyleName"/>

    <xsl:variable name="cellProp" select="key('automatic-styles', $cellStyleName)/style:table-cell-properties" />
    <xsl:variable name="rowProp" select="key('automatic-styles', $rowStyleName)/style:table-row-properties" />
    <xsl:variable name="tableProp" select="key('automatic-styles', $tableStyleName)/style:table-properties" />

    <!-- report lost attributes -->
    <xsl:if test="$cellProp/@style:cell-protect">
      <xsl:message terminate="no">translation.odf2oox.protectedCell</xsl:message>
    </xsl:if>
    <xsl:if test="$cellProp/@style:background-image">
      <xsl:message terminate="no">translation.odf2oox.cellBgImage</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:shadow">
      <xsl:message terminate="no">translation.odf2oox.cellShadow</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:print-content = 'false' ">
      <xsl:message terminate="no">translation.odf2oox.cellContentNotPrinted</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:repeat-content = 'true' ">
      <xsl:message terminate="no">translation.odf2oox.cellContentRepeated</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:rotation-angle">
      <xsl:message terminate="no">translation.odf2oox.cellRotationAngle</xsl:message>
    </xsl:if>
    <xsl:if test="$tableProp/@style:rotation-align">
      <xsl:message terminate="no">translation.odf2oox.cellRotationAlignment</xsl:message>
    </xsl:if>

    <!--
    <xsl:call-template name="InsertCellWidth">
      <xsl:with-param name="tableProp" select="$tableProp"/>
    </xsl:call-template>
-->

    <xsl:call-template name="InsertTableCellWidth">
      <xsl:with-param name="cellPos" select="position() - count(preceding-sibling::table:covered-table-cell)" />
      <xsl:with-param name="cells" select="ancestor::table:table-row/table:table-cell" />
      <xsl:with-param name="columns" select="ancestor::table:table/table:table-column | ancestor::table:table/table:table-columns/table:table-column" />
    </xsl:call-template>

    <xsl:call-template name="InsertCellSpan" />

    <xsl:call-template name="InsertCellBorders">
      <xsl:with-param name="cellProp" select="$cellProp"/>
    </xsl:call-template>

    <xsl:call-template name="InsertCellBgColor">
      <xsl:with-param name="cellProp" select="$cellProp"/>
      <xsl:with-param name="rowProp" select="$rowProp"/>
      <xsl:with-param name="tableProp" select="$tableProp"/>
    </xsl:call-template>

    <w:tcMar>
      <xsl:call-template name="InsertCellMargins">
        <xsl:with-param name="cellProp" select="$cellProp"/>
      </xsl:call-template>
    </w:tcMar>

    <xsl:call-template name="InsertCellWritingMode">
      <xsl:with-param name="cellProp" select="$cellProp"/>
      <xsl:with-param name="tableProp" select="$tableProp"/>
    </xsl:call-template>

    <xsl:call-template name="InsertCellValign">
      <xsl:with-param name="cellProp" select="$cellProp"/>
    </xsl:call-template>
  </xsl:template>


  <!--
  Summary:
  Author:   makz (DIaLOGIKa)
  Params:   cellPos: the position() of the cell
            cells: The node set with all cells in this row
            columns: The node set with all column definitions of this table
  -->
  <xsl:template name="InsertTableCellWidth">
    <xsl:param name="cellPos" />
    <xsl:param name="cells" />
    <xsl:param name="columns" />

    <xsl:variable name="colPos">
      <xsl:call-template name="GetColPos">
        <xsl:with-param name="cellPos" select="$cellPos" />
        <xsl:with-param name="cells" select="$cells" />
        <xsl:with-param name="columns" select="$columns" />
      </xsl:call-template>
    </xsl:variable>

    <!-- get the colspan -->
    <xsl:variable name="colSpan">
      <xsl:choose>
        <xsl:when test="$cells[number($cellPos)]/@table:number-columns-spanned">
          <xsl:value-of select="$cells[number($cellPos)]/@table:number-columns-spanned"/>
        </xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="cellWidth">
      <xsl:call-template name="GetTotalCellWidth">
        <xsl:with-param name="colPos" select="$colPos" />
        <xsl:with-param name="colEndPos" select="$colPos + $colSpan" />
        <xsl:with-param name="columns" select="$columns" />
      </xsl:call-template>
    </xsl:variable>

    <!-- choose if width is relative or absolute -->
    <w:tcW>
      <xsl:variable name="isRelTable">
        <xsl:for-each select="$columns[1]">
          <!-- context switch foreach -->
          <xsl:variable name="tableStyleName" select="parent::table:table/@table:style-name"/>
          <xsl:choose>
            <xsl:when test="key('automatic-styles', $tableStyleName)/style:table-properties/@style:rel-width != ''">
              <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>false</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>

      <xsl:attribute name="w:type">
        <xsl:choose>
          <xsl:when test="$isRelTable='true'">
            <xsl:text>pct</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>dxa</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>


      <xsl:attribute name="w:w">
        <xsl:value-of select="$cellWidth" />
      </xsl:attribute>
    </w:tcW>
  </xsl:template>


  <!--
  Summary:  Adds the width values of the columns to get the total width of the cell that
            spans over the columns.
  Author:   makz (DIaLOGIKa)
  Params:   colPos: The starting position in the column grid
            colEndPos: The last column which width shall be added
            columns: The node set of columns (the column grid)
  -->
  <xsl:template name="GetTotalCellWidth">
    <xsl:param name="colPos" />
    <xsl:param name="colEndPos" />
    <xsl:param name="columns" />
    <xsl:param name="cellWidth">0</xsl:param>
    <xsl:param name="widthType">default</xsl:param>

    <xsl:choose>
      <xsl:when test="$colPos &lt; $colEndPos">

        <xsl:variable name="isRelTable">
          <xsl:for-each select="$columns[1]">
            <!-- context switch foreach -->
            <xsl:variable name="tableStyleName" select="parent::table:table/@table:style-name"/>
            <xsl:choose>
              <xsl:when test="key('automatic-styles', $tableStyleName)/style:table-properties/@style:rel-width != ''">
                <xsl:text>true</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>false</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="styleId" select="$columns[number($colPos)]/@table:style-name" />
        <xsl:variable name="widthString" select="key('automatic-styles', $styleId)/style:table-column-properties/@style:column-width"/>
        <xsl:variable name="relWidthString" select="key('automatic-styles', $styleId)/style:table-column-properties/@style:rel-column-width"/>

        <!-- get the width of this column -->
        <xsl:variable name="width">
          <xsl:choose>
            <xsl:when test="$isRelTable='true' and $relWidthString">
              <xsl:value-of select="substring-before($relWidthString, '*')" />
            </xsl:when>
            <xsl:when test="$isRelTable='false' and $widthString">
              <xsl:value-of select="ooc:TwipsFromMeasuredUnit($widthString)" />
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- add the next width -->
        <xsl:call-template name="GetTotalCellWidth">
          <xsl:with-param name="colPos" select="$colPos + 1" />
          <xsl:with-param name="colEndPos" select="$colEndPos" />
          <xsl:with-param name="columns" select="$columns" />
          <xsl:with-param name="cellWidth" select="$cellWidth + $width" />
          <xsl:with-param name="widthType">
            <xsl:choose>
              <xsl:when test="$widthType = 'default' and $isRelTable='true'">relative</xsl:when>
              <xsl:when test="$widthType = 'default' and $isRelTable='false'">absolute</xsl:when>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <!-- return the value (The value is a ST_DecimalNumberOrPercent, therefore we need rounding here) -->
        <xsl:choose>
          <xsl:when test="$widthType = 'relative'">
            <xsl:value-of select="round(($cellWidth * 5000) div 10000)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="round($cellWidth)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!--
  Summary:  This template adds the colspan of the cells to get the theoretical index of the column
  Author:   makz (DIaLOGIKa)
  Params:   cellPos: The position of the cell, which column should be found
            cells: The node set of all cells in the row
  -->
  <xsl:template name="GetColIndex">
    <xsl:param name="cellPos" />
    <xsl:param name="cells" />
    <xsl:param name="index">1</xsl:param>
    <xsl:param name="iterator">1</xsl:param>

    <xsl:choose>
      <xsl:when test="$iterator &lt; $cellPos">

        <!-- get the colspan of the current cell-->
        <xsl:variable name="colSpan">
          <xsl:choose>
            <xsl:when test="$cells[number($iterator)]/@table:number-columns-spanned">
              <xsl:value-of select="$cells[number($iterator)]/@table:number-columns-spanned"/>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- add this colspan to the current colPos -->
        <xsl:call-template name="GetColIndex">
          <xsl:with-param name="cells" select="$cells" />
          <xsl:with-param name="cellPos" select="$cellPos" />
          <xsl:with-param name="iterator" select="$iterator + 1"/>
          <xsl:with-param name="index" select="$index + $colSpan" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- return the value -->
        <xsl:value-of select="$index"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!--
  Summary:  This templates get the position of the column to which the given cell belongs
  Author:   makz (DIaLOGIKa)
  Params:   cellPos: The position of the cell, which column should be found
            cells: The node set of all cells in the row
            columns: The node set of all columns
  -->
  <xsl:template name="GetColPos">
    <xsl:param name="cellPos" />
    <xsl:param name="cells" />
    <xsl:param name="columns" />
    <xsl:param name="colPos">1</xsl:param>
    <xsl:param name="index">
      <xsl:call-template name="GetColIndex">
        <xsl:with-param name="cells" select="$cells" />
        <xsl:with-param name="cellPos" select="$cellPos" />
      </xsl:call-template>
    </xsl:param>
    <xsl:param name="repeated">
      <xsl:choose>
        <xsl:when test="$columns[1]/@table:number-columns-repeated">
          <xsl:value-of select="$columns[1]/@table:number-columns-repeated"/>
        </xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:param>

    <xsl:choose>
      <xsl:when test="not($index &gt; $repeated)">
        <!-- return the value -->
        <xsl:value-of select="$colPos"/>
      </xsl:when>
      <xsl:otherwise>

        <xsl:variable name="nextRepeat">
          <xsl:choose>
            <xsl:when test="$repeated + $columns[number($colPos)+1]/@table:number-columns-repeated">
              <xsl:value-of select="$repeated + $columns[number($colPos)+1]/@table:number-columns-repeated"/>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:call-template name="GetColPos">
          <xsl:with-param name="cellPos" select="$cellPos" />
          <xsl:with-param name="cells" select="$cells" />
          <xsl:with-param name="columns" select="$columns" />
          <xsl:with-param name="index" select="$index" />
          <xsl:with-param name="colPos" select="$colPos + 1" />
          <xsl:with-param name="repeated" select="$repeated + $nextRepeat" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- 
  Summary: Inserts the cell span 
  Author: makz (DIaLOGIKa)
  Date: 26.10.2007
  -->
  <xsl:template name="InsertCellSpan">

    <!-- horizontal merge -->
    <xsl:choose>
      <xsl:when test="@table:number-columns-spanned">
        <w:gridSpan w:val="{@table:number-columns-spanned}" />
      </xsl:when>

      <!-- covered table cells can also have a colspan if the parent vMerge node has a colspan -->
      <xsl:when test="name(.)='table:covered-table-cell'">

        <xsl:variable name="myRow" select="parent::node()" />
        <xsl:variable name="precedingRow" select="$myRow/preceding-sibling::node()[1]" />
        <xsl:variable name="myPos" select="position()" />
        <xsl:variable name="gridSpan">
          <xsl:choose>
            <!-- 
            the precing row has as many cells as my row,
            so it's the cell above me.
            -->
            <xsl:when test="count($precedingRow/*) = count($myRow/*)">
              <xsl:value-of select="$precedingRow/*[position()=$myPos]/@table:number-columns-spanned"/>
            </xsl:when>
            <!-- 
            the precing row has not the same column count, 
            so try to find the matching node.
            -->
            <xsl:otherwise>
              <xsl:variable name="precedingPos">
                <xsl:call-template name="GetPrecedingPos">
                  <xsl:with-param name="row" select="$precedingRow" />
                  <xsl:with-param name="max" select="$myPos" />
                </xsl:call-template>
              </xsl:variable>
              <xsl:value-of select="$precedingRow/*[position()=$precedingPos]/@table:number-columns-spanned"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="$gridSpan > 0">
          <w:gridSpan w:val="{$gridSpan}" />
        </xsl:if>
      </xsl:when>
    </xsl:choose>

    <!-- vertical merge -->
    <xsl:choose>
      <xsl:when test="@table:number-rows-spanned">
        <w:vMerge w:val="restart" />
      </xsl:when>
      <xsl:when test="name(.)='table:covered-table-cell'">
        <w:vMerge w:val="continue" />
      </xsl:when>
    </xsl:choose>

    

  </xsl:template>

  <!--
  Summary: recursive template
  Author: makz (DIaLOGIKa)
  Date: 22.11.2007
  -->
  <xsl:template name="GetPrecedingPos">
    <xsl:param name="iterator" select="1" />
    <xsl:param name="pos" select="1" />
    <xsl:param name="row" />
    <xsl:param name="max" />

    <xsl:choose>
      <xsl:when test="$iterator &lt; $max">
        <xsl:variable name="cell" select="$row/*[position()=$pos]" />
        <xsl:variable name="addValue">
          <xsl:choose>
            <xsl:when test="$cell/@table:number-columns-spanned">
              <xsl:value-of select="$cell/@table:number-columns-spanned" />
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:call-template name="GetPrecedingPos">
          <xsl:with-param name="iterator" select="$iterator + $addValue" />
          <xsl:with-param name="row" select="$row" />
          <xsl:with-param name="max" select="$max" />
          <xsl:with-param name="pos" select="$pos + 1" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$pos" />
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- 
  Summary: Inserts a single cell border
  Author:  makz (DIaLOGIKa)
  Date:    23.10.2008
  -->
  <xsl:template name="InsertCellBorder">
    <xsl:param name="border" />
    <xsl:param name="borderLineWidth" />
    <xsl:param name="side" />

    <xsl:variable name="widthUnit">
      <xsl:call-template name="GetUnit">
        <xsl:with-param name="length" select="substring-before($border, ' ')" />
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="width">
      <xsl:choose>
        <xsl:when test="contains($border, 'double')">
          <xsl:value-of select="number(substring-before($border, $widthUnit)) div 2" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="number(substring-before($border, $widthUnit))" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="color" select="string(substring-after($border, '#'))" />

    <xsl:variable name="style">
      <xsl:choose>
        <xsl:when test="contains($border, 'double')">
          <xsl:choose>
            <xsl:when test="$borderLineWidth">
              <!-- it is a double border with different line thickness -->
              <xsl:variable name="thickness1" select="number(substring-before($borderLineWidth, $widthUnit))" />
              <xsl:variable name="thickness2" select="number(substring-before(substring-after($borderLineWidth, ' '), $widthUnit))" />
              <xsl:variable name="thickness3" select="number(substring-before(substring-after(substring-after($borderLineWidth, ' '), ' '), $widthUnit))" />
              <xsl:choose>
                <xsl:when test="$thickness1 &gt; $thickness3">
                  <xsl:value-of select="'thickThinMediumGap'"/>
                </xsl:when>
                <xsl:when test="$thickness3 &gt; $thickness1">
                  <xsl:value-of select="'thinThickMediumGap'"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'double'"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <!-- it is a double border with equal line thickness -->
              <xsl:value-of select="'double'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <!-- it is a single border -->
          <xsl:value-of select="'single'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="$width &gt; 0">
      <xsl:element name="{concat('w:', $side)}">

        <xsl:attribute name="w:val">
          <xsl:value-of select="$style" />
        </xsl:attribute>

        <xsl:variable name="widthEigthPoint">
          <xsl:call-template name="ConvertMeasure">
            <xsl:with-param name="length" select="concat($width, $widthUnit)" />
            <xsl:with-param name="unit" select="'eightspoint'"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:attribute name="w:sz">
          <!-- border with has a min of 2 and max of 96 in OpenXML -->
          <xsl:choose>
            <xsl:when test="$widthEigthPoint &lt; 2">2</xsl:when>
            <xsl:when test="$widthEigthPoint &gt; 96">96</xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$widthEigthPoint"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>

        <xsl:attribute name="w:color">
          <xsl:value-of select="$color"/>
        </xsl:attribute>

      </xsl:element>
    </xsl:if>
  </xsl:template>

  <!-- 
  Summary: Inserts the cell borders 
  Author:  makz (DIaLOGIKa)
  Date:    23.10.2008
  Params:  cellProp: The <style:table-cell-properties> element
  -->
  <xsl:template name="InsertCellBorders">
    <xsl:param name="cellProp" />
    <xsl:variable name="colsNumber" select="count(parent::table:table-row/*)"/>

    <w:tcBorders>
      <xsl:choose>
        <xsl:when test="$cellProp/@fo:border">

          <!-- insert the all-around-border to each side -->
          <xsl:call-template name="InsertCellBorder">
            <xsl:with-param name="border" select="$cellProp/@fo:border" />
            <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width" />
            <xsl:with-param name="side" select="string('top')" />
          </xsl:call-template>
          
          <xsl:call-template name="InsertCellBorder">
            <xsl:with-param name="border" select="$cellProp/@fo:border" />
            <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width" />
            <xsl:with-param name="side" select="string('left')" />
          </xsl:call-template>

          <xsl:call-template name="InsertCellBorder">
            <xsl:with-param name="border" select="$cellProp/@fo:border" />
            <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width" />
            <xsl:with-param name="side" select="string('bottom')" />
          </xsl:call-template>

          <xsl:call-template name="InsertCellBorder">
            <xsl:with-param name="border" select="$cellProp/@fo:border" />
            <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width" />
            <xsl:with-param name="side" select="string('right')" />
          </xsl:call-template>

        </xsl:when>
        <xsl:otherwise>

          <!-- insert the single borders -->
          <xsl:if test="$cellProp/@fo:border-top">
            <xsl:call-template name="InsertCellBorder">
              <xsl:with-param name="border" select="$cellProp/@fo:border-top" />
              <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width-top" />
              <xsl:with-param name="side" select="string('top')" />
            </xsl:call-template>
          </xsl:if>
          
          <xsl:if test="$cellProp/@fo:border-left">
            <xsl:call-template name="InsertCellBorder">
              <xsl:with-param name="border" select="$cellProp/@fo:border-left" />
              <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width-left" />
              <xsl:with-param name="side" select="string('left')" />
            </xsl:call-template>
          </xsl:if>

          <xsl:if test="$cellProp/@fo:border-bottom">
            <xsl:call-template name="InsertCellBorder">
              <xsl:with-param name="border" select="$cellProp/@fo:border-bottom" />
              <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width-bottom" />
              <xsl:with-param name="side" select="string('bottom')" />
            </xsl:call-template>
          </xsl:if>
          
          <xsl:if test="$cellProp/@fo:border-right">
            <xsl:call-template name="InsertCellBorder">
              <xsl:with-param name="border" select="$cellProp/@fo:border-right" />
              <xsl:with-param name="borderLineWidth" select="$cellProp/@style:border-line-width-right" />
              <xsl:with-param name="side" select="string('right')" />
            </xsl:call-template>
          </xsl:if>

        </xsl:otherwise>
      </xsl:choose>

    </w:tcBorders>
  </xsl:template>

  <!-- insert cell diagonals inside tcBorders element -->
  <xsl:template name="InsertCellDiagonals">
    <xsl:param name="cellProp"/>

    <xsl:if test="$cellProp[@style:diagonal-tl-br and @style:diagonal-tl-br != 'none']">
      <w:tl2br>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'tl-br'"/>
          <xsl:with-param name="node" select="$cellProp"/>
        </xsl:call-template>
      </w:tl2br>
    </xsl:if>
    <xsl:if test="$cellProp[@style:diagonal-bl-tr and @style:diagonal-bl-tr != 'none']">
      <w:tr2bl>
        <xsl:call-template name="border">
          <xsl:with-param name="side" select="'bl-tr'"/>
          <xsl:with-param name="node" select="$cellProp"/>
        </xsl:call-template>
      </w:tr2bl>
    </xsl:if>
  </xsl:template>

  <!-- Write borders attribute by extracting them from subcells -->
  <xsl:template name="GetBordersFromSubCells">
    <xsl:param name="colsNumber"/>

    <xsl:variable name="SubCellsStyleName"
      select="descendant::node()[self::table:table-cell[parent::table:table-row[1 or last()]] or self::table:table-cell[1 or last()]]/@table:style-name"/>
    <xsl:variable name="subCellsProps"
      select="key('automatic-styles', $SubCellsStyleName)/style:table-cell-properties"/>

    <xsl:choose>
      <xsl:when test="$subCellsProps[@fo:border and @fo:border!='none' ]">
        <!-- NB : value-of takes the first subCell properties only (not the whole node set) -->
        <xsl:call-template name="InsertBorders">
          <xsl:with-param name="allSides">true</xsl:with-param>
          <xsl:with-param name="node" select="$subCellsProps[@fo:border and @fo:border!='none' ][1]"
          />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="topCellsProps"
          select="key('automatic-styles', descendant::table:table-row[1]/table:table-cell/@table:style-name)/style:table-cell-properties"/>
        <xsl:variable name="rightCellsProps"
          select="key('automatic-styles', descendant::table:table-row/table:table-cell[last()]/@table:style-name)/style:table-cell-properties"/>
        <xsl:variable name="leftCellsProps"
          select="key('automatic-styles', descendant::table:table-row/table:table-cell[1]/@table:style-name)/style:table-cell-properties"/>
        <xsl:variable name="bottomCellsProps"
          select="key('automatic-styles', descendant::table:table-row[last()]/table:table-cell/@table:style-name)/style:table-cell-properties"/>

        <xsl:if test="$topCellsProps[@fo:border-top and @fo:border-top != 'none']">
          <!-- NB : value-of takes the first subCell properties only (not the whole node set) -->
          <w:top>
            <xsl:call-template name="border">
              <xsl:with-param name="side" select="'top'"/>
              <xsl:with-param name="node"
                select="$topCellsProps[@fo:border-top and @fo:border-top != 'none'][1]"/>
            </xsl:call-template>
          </w:top>
        </xsl:if>
        <xsl:if test="$leftCellsProps[@fo:border-left and @fo:border-left != 'none']">
          <!-- NB : value-of takes the first subCell properties only (not the whole node set) -->
          <w:left>
            <xsl:call-template name="border">
              <xsl:with-param name="side" select="'left'"/>
              <xsl:with-param name="node"
                select="$leftCellsProps[@fo:border-left and @fo:border-left != 'none'][1]"/>
            </xsl:call-template>
          </w:left>
        </xsl:if>
        <xsl:if test="$bottomCellsProps[@fo:border-bottom and @fo:border-bottom != 'none']">
          <!-- NB : value-of takes the first subCell properties only (not the whole node set) -->
          <w:bottom>
            <xsl:call-template name="border">
              <xsl:with-param name="side" select="'bottom'"/>
              <xsl:with-param name="node"
                select="$bottomCellsProps[@fo:border-bottom and @fo:border-bottom != 'none'][1]"/>
            </xsl:call-template>
          </w:bottom>
        </xsl:if>
        <xsl:if
          test="$rightCellsProps[(@fo:border-right and @fo:border-right != 'none')] or (position() &lt; $colsNumber and position() = 63)">
          <w:right>
            <xsl:choose>
              <xsl:when test="position() &lt; $colsNumber and position() = 63">
                <xsl:call-template name="border">
                  <xsl:with-param name="side" select="'right'"/>
                  <xsl:with-param name="node"
                    select="$subCellsProps[@fo:border-right and @fo:border-right != 'none'][1]"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="border">
                  <xsl:with-param name="side" select="'right'"/>
                  <xsl:with-param name="node"
                    select="$rightCellsProps[@fo:border-right and @fo:border-right != 'none'][1]"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </w:right>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Write border attribute except if cell is on the border of the subtable -->
  <xsl:template name="GetSubCellBorders">
    <xsl:param name="cellProp"/>
    <xsl:param name="colsNumber"/>

    <xsl:choose>
      <!-- if subtable, get the border from subcells -->
      <xsl:when test="table:table[@table:is-sub-table='true']">
        <xsl:call-template name="GetBordersFromSubCells">
          <xsl:with-param name="colsNumber" select="$colsNumber"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if
          test="$cellProp[(@fo:border and @fo:border!='none') or (@fo:border-top and @fo:border-top != 'none')] and parent::table:table-row/preceding-sibling::table:table-row">
          <w:top>
            <xsl:call-template name="border">
              <xsl:with-param name="side" select="'top'"/>
              <xsl:with-param name="node" select="$cellProp"/>
            </xsl:call-template>
          </w:top>
        </xsl:if>
        <xsl:if
          test="$cellProp[(@fo:border and @fo:border!='none') or (@fo:border-left and @fo:border-left != 'none')] and not(position()=1)">
          <w:left>
            <xsl:call-template name="border">
              <xsl:with-param name="side" select="'left'"/>
              <xsl:with-param name="node" select="$cellProp"/>
            </xsl:call-template>
          </w:left>
        </xsl:if>
        <xsl:if
          test="$cellProp[(@fo:border and @fo:border!='none') or (@fo:border-bottom and @fo:border-bottom != 'none')] and parent::table:table-row/following-sibling::table:table-row">
          <w:bottom>
            <xsl:call-template name="border">
              <xsl:with-param name="side" select="'bottom'"/>
              <xsl:with-param name="node" select="$cellProp"/>
            </xsl:call-template>
          </w:bottom>
        </xsl:if>
        <xsl:if
          test="($cellProp[(@fo:border and @fo:border!='none') or (@fo:border-right and @fo:border-right != 'none')] or (position() &lt; $colsNumber and position() = 63)) and not(position()=last())">
          <w:right>
            <xsl:call-template name="border">
              <xsl:with-param name="side" select="'right'"/>
              <xsl:with-param name="node" select="$cellProp"/>
            </xsl:call-template>
          </w:right>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts the cell boackground color -->
  <xsl:template name="InsertCellBgColor">
    <xsl:param name="cellProp"/>
    <xsl:param name="rowProp"/>
    <xsl:param name="tableProp"/>
    <xsl:choose>
      <xsl:when
        test="$cellProp/@fo:background-color and $cellProp/@fo:background-color != 'transparent' ">
        <w:shd w:val="clear" w:color="auto"
          w:fill="{substring($cellProp/@fo:background-color, 2, string-length($cellProp/@fo:background-color) -1)}"
        />
      </xsl:when>

      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$rowProp/@fo:background-color and $rowProp/@fo:background-color != 'transparent' ">
            <w:shd w:val="clear" 
                   w:color="auto" 
                   w:fill="{substring($rowProp/@fo:background-color, 2, string-length($rowProp/@fo:background-color) -1)}" />
          </xsl:when>
          <xsl:when test="$tableProp/@fo:background-color and $tableProp/@fo:background-color != 'transparent' ">
            <w:shd w:val="clear" 
                   w:color="auto"
                   w:fill="{substring($tableProp/@fo:background-color, 2, string-length($tableProp/@fo:background-color) -1)}" />
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts the cell margins -->
  <xsl:template name="InsertCellMargins">
    <xsl:param name="cellProp"/>
    <xsl:param name="defaultMargin" select="'false'"/>
    <xsl:choose>
      <xsl:when test="$defaultMargin = 'false' and table:table[@table:is-sub-table='true']">
        <w:top w:w="0" w:type="dxa"/>
        <w:left w:w="0" w:type="dxa"/>
        <w:bottom w:w="0" w:type="dxa"/>
        <w:right w:w="0" w:type="dxa"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$cellProp[@fo:padding and @fo:padding != 'none']">
            <xsl:variable name="padding" select="ooc:TwipsFromMeasuredUnit($cellProp/@fo:padding)" />

            <w:top w:type="dxa" w:w="{$padding}" />
            <w:left w:type="dxa" w:w="{$padding}" />
            <w:bottom w:type="dxa" w:w="{$padding}" />
            <w:right w:type="dxa" w:w="{$padding}" />
          </xsl:when>
          <xsl:otherwise>
            <w:top w:type="dxa" w:w="{ooc:TwipsFromMeasuredUnit($cellProp/@fo:padding-top)}" />
            <w:left w:type="dxa" w:w="{ooc:TwipsFromMeasuredUnit($cellProp/@fo:padding-left)}" />
            <w:bottom w:type="dxa" w:w="{ooc:TwipsFromMeasuredUnit($cellProp/@fo:padding-bottom)}" />
            <w:right w:type="dxa" w:w="{ooc:TwipsFromMeasuredUnit($cellProp/@fo:padding-right)}" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts the cell writing mode -->
  <xsl:template name="InsertCellWritingMode">
    <xsl:param name="cellProp"/>
    <xsl:param name="tableProp"/>
    <xsl:choose>
      <xsl:when test="$cellProp/@style:direction = 'ltr' ">
        <w:textDirection w:val="lrTb"/>
      </xsl:when>
      <xsl:when test="$cellProp/@style:direction = 'ttb' ">
        <w:textDirection w:val="tbRl"/>
      </xsl:when>
      <xsl:when test="$tableProp/@style:writing-mode = 'tb-rl' ">
        <w:textDirection w:val="tbRl"/>
      </xsl:when>
      <xsl:when test="$tableProp/@style:writing-mode = 'lr-tb' ">
        <w:textDirection w:val="lrTb"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts the cell vertical alignment -->
  <xsl:template name="InsertCellValign">
    <xsl:param name="cellProp"/>
    <xsl:if
      test="$cellProp[@style:vertical-align and @style:vertical-align!='' and @style:vertical-align!='automatic']">
      <xsl:choose>
        <xsl:when test="$cellProp/@style:vertical-align = 'middle'">
          <w:vAlign w:val="center"/>
        </xsl:when>
        <xsl:otherwise>
          <w:vAlign w:val="{$cellProp/@style:vertical-align}"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- Inserts an empty paragraph -->
  <xsl:template name="InsertEmptyParagraph">
    <w:p>
      <w:pPr>
        <w:framePr w:wrap="around" w:vAnchor="text" w:hAnchor="text" w:y="1"/>
        <w:suppressOverlap/>
      </w:pPr>
    </w:p>
  </xsl:template>

  <!-- Inserts a page break before if needed -->
  <xsl:template name="InsertPageBreakBefore">
    <xsl:variable name="isFirstParagraphOfTable">
      <xsl:call-template name="IsFirstParagraphOfTable"/>
    </xsl:variable>
    <xsl:if test="$isFirstParagraphOfTable = 'true' ">
      <!-- if associated style has a pgBreakBefore property -->
      <xsl:if
        test="key('automatic-styles', ancestor::table:table[1]/@table:style-name)/style:table-properties/@fo:break-before = 'page'
        or key('automatic-styles', ancestor::table:table[1]/@table:style-name)/@style:master-page-name != ''">
        <w:pageBreakBefore/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- template to know if context paragraph is first of table. returns 'true' or 'false' -->
  <xsl:template name="IsFirstParagraphOfTable">
    <xsl:choose>
      <!-- in the first paragraph of a table -->
      <xsl:when test="not(preceding-sibling::text:p) and ancestor-or-self::table:table">
        <xsl:choose>
          <!-- if first cell -->
          <xsl:when test="parent::table:table-cell[not(preceding-sibling::node())]">
            <xsl:choose>
              <!-- if first row -->
              <xsl:when
                test="ancestor::table:table-row[not(@table:number-rows-repeated &gt; 1) and (preceding-sibling::*[1][self::table:table-column or self::table:table-columns] or not(preceding-sibling::node()))]"
                >true</xsl:when>
              <xsl:otherwise>false</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>false</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- compare values of spacing before/after and return 0 or the spacing value to override -->
  <xsl:template name="CompareSpacingValues">
    <xsl:param name="tableSide"/>
    <xsl:param name="paraSide"/>

    <!-- get spacing value of table properties -->
    <xsl:variable name="tableSpace">
      <xsl:choose>
        <xsl:when test="$tableSide='top' and key('automatic-styles', following-sibling::node()[1][name()='table:table']/@table:style-name)/style:table-properties/attribute::node()[name()=concat('fo:margin-',$tableSide)]">
          <xsl:call-template name="twips-measure">
            <xsl:with-param name="length" select="key('automatic-styles',following-sibling::node()[1][name()='table:table']/@table:style-name)/style:table-properties/attribute::node()[name()=concat('fo:margin-',$tableSide)]" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$tableSide='bottom' and key('automatic-styles',preceding-sibling::node()[1][name()='table:table']/@table:style-name)/style:table-properties/attribute::node()[name()=concat('fo:margin-',$tableSide)]">
          <xsl:call-template name="twips-measure">
            <xsl:with-param name="length" select="key('automatic-styles',preceding-sibling::node()[1][name()='table:table']/@table:style-name)/style:table-properties/attribute::node()[name()=concat('fo:margin-',$tableSide)]" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- if spacing value of table is 0, do not override. -->
    <xsl:choose>
      <xsl:when test="$tableSpace != 0">
        <!-- get spacing value of paragraph style -->
        <xsl:variable name="paraSpace">
          <xsl:choose>
            <xsl:when test="key('automatic-styles',@text:style-name)/style:paragraph-properties/attribute::node()[name()=concat('fo:margin-',$paraSide)]">
              <xsl:value-of select="ooc:TwipsFromMeasuredUnit(key('automatic-styles',@text:style-name)/style:paragraph-properties/attribute::node()[name()=concat('fo:margin-',$paraSide)])" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="document('styles.xml')">
                <xsl:value-of select="ooc:TwipsFromMeasuredUnit(key('styles',@text:style-name)/style:paragraph-properties/attribute::node()[name()=concat('fo:margin-',$paraSide)])" />
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- compare those two values and choose which one is best -->
        <xsl:choose>
          <xsl:when test="$tableSpace &gt; $paraSpace">
            <xsl:value-of select="$tableSpace"/>
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
