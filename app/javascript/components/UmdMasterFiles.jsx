import React from 'react';

// UMD custom component for displaying a list of master file downloads
// as a tab in the MediaObjectRamp sidebar.
const UmdMasterFiles = ({ masterFiles }) => {
  const renderMasterFileDownload = (masterFile) => {
    return (
      <dd key={masterFile.id}>
        <a href={masterFile.url}>{masterFile.fileLabel}</a>
      </dd>
    );
  };

  return (
    <div data-testid="supplemental-files" className="ramp--supplemental-files">
      <div className="ramp--supplemental-files-display-content">
        <h4>Media files</h4>
        <dl>
          {masterFiles.downloads.map((download) => renderMasterFileDownload(download))}
        </dl>
      </div>
    </div>
  );
};

export default UmdMasterFiles;
