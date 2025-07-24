import React from 'react';

const UmdMasterFileDownloads = ({ masterFiles }) => {
  const renderMasterFileDownload = (masterFile) => {
    return (
      <li>
        <a href={masterFile.url}>{masterFile.fileName}</a>
      </li>
    );
  };

  return (
    <div>
      {masterFiles.map((masterFile) => renderMasterFileDownload(masterFile))}
    </div>
  );
};

export default UmdMasterFileDownloads;