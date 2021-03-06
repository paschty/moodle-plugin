<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink"
                version="3.0">
  <xsl:param name="WebApplicationBaseURL"/>

  <xsl:variable name="translations" select="document('translate:mir.moodle.')"/>

  <xsl:template match="MoodleCall">
    <site>
      <xsl:choose>
        <xsl:when test="@method='core_course_get_courses'">
          <xsl:call-template name="importCourse"/>
        </xsl:when>
        <xsl:when test="@method='core_enrol_get_users_courses'">
          <xsl:call-template name="listCourses"/>
        </xsl:when>
        <xsl:when test="@method='no_user'">
          <xsl:call-template name="userMissing"/>
        </xsl:when>
        <xsl:when test="@method='importResult'">
          <xsl:call-template name="importResult" />
        </xsl:when>
      </xsl:choose>
    </site>
  </xsl:template>

  <!-- #### Course no user linked error ############################################################################ -->
  <xsl:template name="userMissing">
    <div class="card">
      <div class="card-header">
        <h2 class="card-title">
          <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.user.missing.title']/text()"/>
        </h2>
      </div>
      <div class="card-body">
        <p>
          <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.user.missing.message']/text()"/>
        </p>
        <form method="GET" action="{$WebApplicationBaseURL}servlets/MoodleServlet">
          <p>Geben sie die NutzerID des Moodle-Nutzers ein!</p>
          <img src="{$WebApplicationBaseURL}moodle/img/profile.png" /><br/>
          <span>Aus der Browserleiste kopieren: </span>
          <code>https://moodletest.zim.uni-due.de/moodle_37_test/user/profile.php?id=<b style="color:red;">20</b></code><br/>
          <input type="hidden" name="action" value="userEdit" />
          <input type="number" name="userID" />
          <input type="submit" />
        </form>
      </div>
    </div>
  </xsl:template>

  <!-- #### Course list ############################################################################################ -->
  <xsl:template name="listCourses">
    <div class="card">
      <div class="card-header">
        <h2>
          <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.choose.course.title']/text()"/>
        </h2>
      </div>
      <div class="card-body">
        <p>
          <xsl:value-of
              select="$translations/translations/translation[@key='mir.moodle.choose.course.description']/text()"/>
        </p>
      </div>
      <ul class="list-group list-group-flush">
        <!-- TODO: filter existing courses
        <xsl:variable name="servflagField" select="'servflag.type.IMPORTED_MOODLE_COURSE'" />
        <xsl:variable name="query" select="concat('q=', $servflagField, ':(', string-join(RESPONSE/MULTIPLE/SINGLE/KEY[@name='id']/VALUE, ' or '), ')', '&amp;rows=99999&amp;fl=id,', $servflagField)" />
        <xsl:variable name="result" select="document(concat('solr:', $query))" />
        <xsl:variable name="presentIDList" select="$result/response/result/doc/str[@name=$servflagField]"/>
        <xsl:apply-templates select="RESPONSE/MULTIPLE/SINGLE[count(index-of($presentIDList, KEY[@name='id']/VALUE/text()))=0]"/>
        -->

        <xsl:apply-templates select="RESPONSE/MULTIPLE/SINGLE"/>
      </ul>
    </div>
  </xsl:template>

  <xsl:template match="MoodleCall[@method='core_enrol_get_users_courses']/RESPONSE/MULTIPLE/SINGLE">

    <li class="list-group-item">
      <a href="{$WebApplicationBaseURL}servlets/MoodleServlet?importID={KEY[@name='id']/VALUE/text()}">
        <xsl:value-of select="KEY[@name='fullname']/VALUE/text()"/>
      </a>
    </li>
  </xsl:template>

  <!-- #### Course import select contents ########################################################################## -->
  <xsl:template name="importCourse">
    <xsl:variable name="courseID" select="RESPONSE/MULTIPLE/SINGLE/KEY[@name='id']/VALUE/text()"/>
    <xsl:variable name="courseContent" select="document(concat('moodle:resolveCourseContent:', $courseID))"/>
    <div class="card">
      <div class="card-header">
        <h2>
          <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.import.course.title']/text()"/>
        </h2>
      </div>
      <div class="card-body">
        <p>
          <xsl:value-of
              select="$translations/translations/translation[@key='mir.moodle.import.course.description']/text()"/>
        </p>
        <p class="d-none text-danger fileNotLinkedValidation">
          <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.import.course.validation.filesNoParent']/text()" />
        </p>
        <form method="post" class="moodleRoot" action="{$WebApplicationBaseURL}servlets/MoodleServlet">
          <input type="hidden" name="importID" value="{$courseID}"/>
          <xsl:variable name="courseTitle" select="RESPONSE/MULTIPLE/SINGLE/KEY[@name='fullname']/VALUE/text()"/>

          <div class="form-check">
            <input class="form-check-input" type="checkbox" name="course" id="course_{$courseID}"
                   value="{$courseID}" checked="true"/>
            <label class="form-check-label" for="course_{$courseID}">
              <xsl:value-of select="$courseTitle"/>
            </label>
          </div>

          <xsl:for-each select="$courseContent/RESPONSE/MULTIPLE/SINGLE">
            <xsl:call-template name="printModule"/>
          </xsl:for-each>

          <button type="submit" class="btn btn-primary float-right" onclick="return validateContents()">
            <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.import.submit']/text()"/>
          </button>
        </form>
        <script src="{$WebApplicationBaseURL}moodle/js/select-contents-restriction.js"> </script>
      </div>
    </div>

  </xsl:template>

  <xsl:template name="printModule">
    <xsl:variable name="supported" select=".//KEY[@name='modname']/VALUE/text()='resource'"/>
    <div class="ml-4">
      <xsl:variable name="moduleID" select="KEY[@name='id']/VALUE/text()"/>
      <div class="form-check">

        <input class="form-check-input" type="checkbox" name="module"
               enabled="{$supported}"
               value="{$moduleID}">
          <xsl:if test="$supported">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
          <xsl:if test="not($supported)">
            <xsl:attribute name="disabled">disabled</xsl:attribute>
          </xsl:if>
        </input>

        <label class="form-check-label" for="module_{$moduleID}">
          <xsl:value-of select="KEY[@name='name']/VALUE/text()"/>
        </label>
      </div>
      <!-- File-Content -->
      <xsl:for-each select="KEY[@name='contents']/MULTIPLE/SINGLE">
        <xsl:call-template name="printFile"/>
      </xsl:for-each>
      <!-- Child-Modules  -->
      <xsl:for-each select="KEY[@name='modules']/MULTIPLE/SINGLE">
        <xsl:call-template name="printModule"/>
      </xsl:for-each>

    </div>
  </xsl:template>

  <xsl:template name="printFile">
    <div class="ml-4">
      <div class="form-check">
        <xsl:variable name="fileID" select="KEY[@name='fileurl']/VALUE/text()"/>
        <input class="form-check-input" type="checkbox" name="file" value="{$fileID}" checked="true"/>
        <xsl:variable name="parents">
          <xsl:for-each select="./ancestor::SINGLE[count(KEY[@name='id'])&gt;0]">
            <xsl:if test="position()&gt;1">
              <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:value-of select="KEY[@name='id']/VALUE/text()" />
          </xsl:for-each>
        </xsl:variable>
        <input name="parent" type="hidden" value="{$fileID}$$${$parents}" />

        <label class="form-check-label" for="module_">
          <xsl:value-of select="KEY[@name='filename']/VALUE/text()"/>
        </label>
      </div>
    </div>
  </xsl:template>


  <xsl:template name="importResult">
    <div class="card">
      <div class="card-header">
        <h2 class="card-title">
          <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.import.success']/text()"/>
        </h2>
      </div>
      <div class="card-body">
        <p>
          <xsl:value-of select="$translations/translations/translation[@key='mir.moodle.import.message']/text()"/>
        </p>
      </div>
      <ul class="list-group list-group-flush">
        <xsl:for-each select="object">
          <xsl:variable name="mcrObject" select="document(concat('mcrobject:', @id))" />
          <li class="list-group-item">
            <xsl:variable name="modsTitleInfoElement" select="$mcrObject/mycoreobject/metadata/def.modsContainer/modsContainer/mods:mods/mods:titleInfo" />
            <xsl:variable name="hasTitle" select="count($modsTitleInfoElement/mods:title) &gt;0" />
            <xsl:variable name="hasSubTitle" select="count($modsTitleInfoElement/mods:subTitle) &gt;0" />
            <xsl:variable name="titleString">
              <xsl:choose>
                <xsl:when test="$hasTitle and $hasSubTitle">
                  <xsl:value-of select="$modsTitleInfoElement/mods:title" />: <xsl:value-of select="$modsTitleInfoElement/mods:subTitle" />
                </xsl:when>
                <xsl:when test="$hasTitle">
                  <xsl:value-of select="$modsTitleInfoElement/mods:title" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@id" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <a target="_blank" href="{$WebApplicationBaseURL}receive/{@id}"><xsl:value-of select="$titleString"/><span class="ml-1 fas fa-external-link-alt"> </span></a>
          </li>
        </xsl:for-each>
      </ul>
    </div>
  </xsl:template>

</xsl:stylesheet>